#!/usr/bin/env bash
set -euo pipefail

readonly workspace="${PWD}"
readonly evidence_relative="${1:?evidence directory is required}"
readonly evidence="${workspace}/${evidence_relative}"
# This is the linux/amd64 child manifest for Hummingbird core-runtime 2.43.
readonly payload='registry.access.redhat.com/hi/core-runtime@sha256:43ef8f951915c7cc58c5c45ceeed318ab5206139d10153099a097a8c0a14f16e'
readonly container_name="nested-podman-smoke-${$}"

cleanup() {
  podman rm --force "${container_name}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

mkdir -p "${evidence}"

if [[ "$(id -u)" == 0 || "$(id -u)" != 1000 || "$(id -g)" != 1001 ]]; then
  printf 'The outer remote user must be the verified UID 1000 and GID 1001.\n' >&2
  exit 1
fi

if [[ ! -d "${workspace}" || ! -w "${workspace}" ]]; then
  printf 'The mounted workspace is not writable: %s\n' "${workspace}" >&2
  exit 1
fi
probe="${workspace}/.nested-podman-write-${$}"
: > "${probe}"
rm -f "${probe}"

{
  id
  printf '%s\n' '--- /proc/self/uid_map'
  cat /proc/self/uid_map
  printf '%s\n' '--- /proc/self/gid_map'
  cat /proc/self/gid_map
  printf '%s\n' '--- /etc/subuid'
  cat /etc/subuid
  printf '%s\n' '--- /etc/subgid'
  cat /etc/subgid
} > "${evidence}/outer-identity-and-maps.txt"

mapfile -t uid_map < /proc/self/uid_map
mapfile -t gid_map < /proc/self/gid_map
if [[ "${uid_map[*]}" != *'0          1       1000'* ||
      "${uid_map[*]}" != *'1000          0          1'* ||
      "${uid_map[*]}" != *'1001       1001      64536'* ||
      "${gid_map[*]}" != *'0          1       1001'* ||
      "${gid_map[*]}" != *'1001          0          1'* ||
      "${gid_map[*]}" != *'1002       1002      64535'* ]]; then
  printf 'The observed outer UID/GID maps do not match the verified host.\n' >&2
  exit 1
fi

podman info --format json > "${evidence}/nested-podman-info.json"
if [[ "$(podman info --format '{{.Host.Security.Rootless}}')" != true ]]; then
  printf 'The nested engine did not report rootless operation.\n' >&2
  exit 1
fi
if [[ "$(podman info --format '{{.Store.GraphDriverName}}')" != vfs ]]; then
  printf 'The nested engine is not using the required vfs storage driver.\n' >&2
  exit 1
fi

podman unshare cat /proc/self/uid_map > "${evidence}/nested-uid-map.txt"
podman unshare cat /proc/self/gid_map > "${evidence}/nested-gid-map.txt"
cp /usr/local/share/nested-podman/package-provenance.txt \
  "${evidence}/package-provenance.txt"
cp /usr/local/share/nested-podman/all-package-provenance.txt \
  "${evidence}/all-package-provenance.txt"
{
  for repository in /etc/yum.repos.d/*.repo; do
    printf '%s\n' "--- ${repository}"
    cat "${repository}"
  done
} > "${evidence}/runtime-repositories.txt"

podman pull "${payload}" > "${evidence}/payload-pull.log" 2>&1
podman image inspect "${payload}" > "${evidence}/payload-image-inspect.json"
podman ps --all --format '{{.ID}}\t{{.Names}}\t{{.Status}}' \
  > "${evidence}/inner-containers-before.txt"

# Rootless-in-rootless crun could not set a hostname in a third UTS namespace.
# Sharing the outer container's private UTS namespace avoids adding a capability.
podman create \
  --name "${container_name}" \
  --network=none \
  --cgroups=disabled \
  --uts=host \
  --pull=never \
  "${payload}" \
  /bin/bash -c "printf 'nested podman ok\\n'" \
  > "${evidence}/inner-container-create.txt"
podman inspect "${container_name}" > "${evidence}/inner-container-inspect.json"

set +e
smoke_output="$(podman start --attach "${container_name}")"
smoke_status=$?
set -e
printf '%s\n' "${smoke_output}" > "${evidence}/smoke.stdout"
printf '%s\n' "${smoke_status}" > "${evidence}/smoke.status"

podman rm "${container_name}" > "${evidence}/inner-container-remove.txt"
podman ps --all --format '{{.ID}}\t{{.Names}}\t{{.Status}}' \
  > "${evidence}/inner-containers-after.txt"
trap - EXIT

if [[ ${smoke_status} -ne 0 || "${smoke_output}" != 'nested podman ok' ]]; then
  printf 'The inner smoke-test container failed or emitted unexpected output.\n' >&2
  exit 1
fi

printf 'nested podman ok\n'

#!/usr/bin/env bash
set -euo pipefail

readonly workspace="${PWD}"
readonly evidence_relative="${1:?evidence directory is required}"
readonly evidence="${workspace}/${evidence_relative}"
# This is the linux/amd64 child manifest for Hummingbird core-runtime 2.43.
readonly payload='registry.access.redhat.com/hi/core-runtime@sha256:43ef8f951915c7cc58c5c45ceeed318ab5206139d10153099a097a8c0a14f16e'
readonly container_name="nested-podman-smoke-${$}"
readonly outer_uid=1000
readonly outer_gid=1001
readonly subordinate_limit=65536

cleanup() {
  podman rm --force "${container_name}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

derive_subordinate_ranges() {
  local own_id="$1"

  if (( own_id > 1 )); then
    printf '1:%s\n' "$((own_id - 1))"
  fi
  if (( own_id < subordinate_limit )); then
    printf '%s:%s\n' "$((own_id + 1))" "$((subordinate_limit - own_id))"
  fi
}

validate_map_file() {
  local map_file="$1"
  local map_name="$2"
  local inside parent length extra
  local entries=0
  local previous_end=-1

  while read -r inside parent length extra; do
    [[ -z "${extra}" && "${inside}" =~ ^[0-9]+$ && \
       "${parent}" =~ ^[0-9]+$ && "${length}" =~ ^[0-9]+$ ]] || \
      fail "The observed ${map_name} contains a malformed entry."
    (( 10#${length} > 0 )) || fail "The observed ${map_name} contains an empty entry."
    (( 10#${inside} > previous_end )) || \
      fail "The observed ${map_name} is overlapping or out of order."
    previous_end=$((10#${inside} + 10#${length} - 1))
    entries=$((entries + 1))
  done < "${map_file}"

  (( entries > 0 )) || fail "The observed ${map_name} is empty."
}

map_has_entry() {
  local map_file="$1"
  local expected_inside="$2"
  local expected_parent="$3"
  local expected_length="$4"
  local inside parent length

  while read -r inside parent length; do
    if (( 10#${inside} == expected_inside && \
          10#${parent} == expected_parent && \
          10#${length} == expected_length )); then
      return 0
    fi
  done < "${map_file}"
  return 1
}

range_is_mapped() {
  local map_file="$1"
  local range_start="$2"
  local range_count="$3"
  local cursor="${range_start}"
  local range_end=$((range_start + range_count - 1))
  local inside parent length map_end

  while read -r inside parent length; do
    inside=$((10#${inside}))
    length=$((10#${length}))
    map_end=$((inside + length - 1))
    (( map_end >= cursor )) || continue
    (( inside <= cursor )) || return 1
    (( map_end < range_end )) || return 0
    cursor=$((map_end + 1))
  done < "${map_file}"
  return 1
}

validate_subordinate_config() {
  local ranges_file="$1"
  local map_file="$2"
  local account="$3"
  local own_id="$4"
  local id_kind="$5"
  local owner start count
  local -a expected=()
  local -a actual=()

  mapfile -t expected < <(derive_subordinate_ranges "${own_id}")
  while IFS=: read -r owner start count; do
    [[ "${owner}" == "${account}" ]] || continue
    actual+=("${start}:${count}")
  done < "${ranges_file}"

  [[ "${actual[*]}" == "${expected[*]}" ]] || \
    fail "The nested subordinate ${id_kind} ranges do not match the fixed outer identity."

  for range in "${expected[@]}"; do
    IFS=: read -r start count <<< "${range}"
    range_is_mapped "${map_file}" "${start}" "${count}" || \
      fail "A nested subordinate ${id_kind} range is not mapped in the observed outer namespace."
  done
}

validate_nested_map() {
  local map_file="$1"
  local own_id="$2"
  local map_name="$3"
  local inside parent length range_start range_count
  local next_inside=1
  local -a expected=("0:${own_id}:1")
  local -a actual=()

  while IFS=: read -r range_start range_count; do
    expected+=("${next_inside}:${range_start}:${range_count}")
    next_inside=$((next_inside + range_count))
  done < <(derive_subordinate_ranges "${own_id}")
  (( next_inside == subordinate_limit )) || \
    fail "The derived nested ${map_name} does not contain 65,536 IDs."

  while read -r inside parent length; do
    actual+=("$((10#${inside})):$((10#${parent})):$((10#${length}))")
  done < "${map_file}"
  [[ "${actual[*]}" == "${expected[*]}" ]] || \
    fail "The observed nested ${map_name} does not compose through the outer namespace."
}

mkdir -p "${evidence}"
install -d -m 0700 /dev/shm/nested-podman-build

if [[ "$(id -u)" == 0 || "$(id -u)" != "${outer_uid}" || \
      "$(id -g)" != "${outer_gid}" ]]; then
  fail 'The outer remote user must have fixed container UID 1000 and GID 1001.'
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

validate_map_file /proc/self/uid_map 'outer UID map'
validate_map_file /proc/self/gid_map 'outer GID map'
map_has_entry /proc/self/uid_map "${outer_uid}" 0 1 || \
  fail 'Explicit keep-id did not map the invoking host user to outer UID 1000.'
map_has_entry /proc/self/gid_map "${outer_gid}" 0 1 || \
  fail 'Explicit keep-id did not map the invoking host primary group to outer GID 1001.'
validate_subordinate_config /etc/subuid /proc/self/uid_map \
  nonroot "${outer_uid}" UID
validate_subordinate_config /etc/subgid /proc/self/gid_map \
  nonroot "${outer_gid}" GID

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
validate_map_file "${evidence}/nested-uid-map.txt" 'nested UID map'
validate_map_file "${evidence}/nested-gid-map.txt" 'nested GID map'
validate_nested_map "${evidence}/nested-uid-map.txt" "${outer_uid}" 'UID map'
validate_nested_map "${evidence}/nested-gid-map.txt" "${outer_gid}" 'GID map'
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

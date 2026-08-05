#!/usr/bin/env bash
set -euo pipefail

readonly repo_dir="${PWD}"
readonly config="${repo_dir}/.devcontainer/devcontainer.json"
readonly builder_image='registry.access.redhat.com/hi/core-runtime@sha256:32bfa924b015b66d61ba5450dc12f5a8693e32e8c38be8eb7c440395806f9ee7'
readonly run_id="${EPOCHSECONDS}-${$}"
readonly evidence_relative=".devcontainer/evidence/${run_id}"
readonly evidence="${repo_dir}/${evidence_relative}"

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

[[ "${EUID}" -ne 0 ]] || fail 'Run this recipe as a non-root host user.'
# This is a verification-host guard, not a Podman requirement. See the README
# before adapting keep-id for a host whose UID or primary GID differs.
[[ "${EUID}" -eq 1000 && "$(id -g)" -eq 1001 ]] || \
  fail 'Use or adapt the verified host identity: UID 1000 and GID 1001.'
[[ "$(uname -m)" == x86_64 ]] || \
  fail 'Use or adapt the verified x86_64 host architecture.'
command -v devcontainer >/dev/null || fail 'Install the Dev Container CLI, then retry.'
command -v podman >/dev/null || fail 'Install rootless Podman, then retry.'
command -v just >/dev/null || fail 'Install Just, then retry.'
[[ "$(podman info --format '{{.Host.Security.Rootless}}')" == true ]] || \
  fail 'Configure Podman for the current non-root host user, then retry.'

subuid_ok=false
while IFS=: read -r name start count; do
  if [[ "${name}" == "${USER}" && "${start}" == 100000 && "${count}" -ge 65536 ]]; then
    subuid_ok=true
  fi
done < /etc/subuid
[[ "${subuid_ok}" == true ]] || \
  fail 'Ask the host owner to provide or adapt the verified subordinate UID range.'

subgid_ok=false
while IFS=: read -r name start count; do
  if [[ "${name}" == "${USER}" && "${start}" == 100000 && "${count}" -ge 65536 ]]; then
    subgid_ok=true
  fi
done < /etc/subgid
[[ "${subgid_ok}" == true ]] || \
  fail 'Ask the host owner to provide or adapt the verified subordinate GID range.'

set +e
up_output="$(devcontainer up \
  --workspace-folder "${repo_dir}" \
  --config "${config}" \
  --docker-path podman \
  --mount-workspace-git-root=false 2>&1)"
up_status=$?
set -e
if [[ ${up_status} -ne 0 ]]; then
  printf '%s\n' "${up_output}" >&2
  fail 'Dev Container launch failed; no host prerequisite was changed.'
fi

if [[ ! "${up_output}" =~ \"containerId\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
  fail 'Dev Container CLI did not report the outer container identity.'
fi
readonly container_id="${BASH_REMATCH[1]}"

# Create the ignored evidence directory through the Dev Container exec boundary
# so the host orchestration does not need a separate filesystem setup command.
devcontainer exec \
  --workspace-folder "${repo_dir}" \
  --config "${config}" \
  --docker-path podman \
  --mount-workspace-git-root=false \
  /bin/bash -c "mkdir -p '${evidence_relative}'" >/dev/null 2>&1

printf '%s\n' "${up_output}" > "${evidence}/devcontainer-up.log"
printf '%s\n' "${up_status}" > "${evidence}/devcontainer-up.status"

{
  printf '%s\n' \
    'just test-podman' \
    'id' \
    'uname -a' \
    'just --version' \
    'devcontainer --version' \
    "podman info --format {{.Host.Security.Rootless}}" \
    "devcontainer up --workspace-folder ${repo_dir} --config ${config} --docker-path podman --mount-workspace-git-root=false" \
    "devcontainer exec --workspace-folder ${repo_dir} --config ${config} --docker-path podman --mount-workspace-git-root=false /bin/bash -c mkdir -p ${evidence_relative}" \
    'podman --version' \
    "podman image inspect ${builder_image}" \
    "podman inspect ${container_id}" \
    'podman info --format json' \
    'git rev-parse HEAD' \
    "devcontainer exec --workspace-folder ${repo_dir} --config ${config} --docker-path podman --mount-workspace-git-root=false /usr/local/bin/test-nested-podman ${evidence_relative}"
} > "${evidence}/host-commands.txt"

{
  id
  uname -a
  just --version
  devcontainer --version
  podman --version
  printf '%s\n' '--- /etc/subuid'
  while IFS= read -r line; do printf '%s\n' "${line}"; done < /etc/subuid
  printf '%s\n' '--- /etc/subgid'
  while IFS= read -r line; do printf '%s\n' "${line}"; done < /etc/subgid
  printf '%s\n' '--- repository revision'
  if command -v git >/dev/null && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git rev-parse HEAD
  else
    printf '%s\n' 'not recorded: no enclosing Git work tree'
  fi
} > "${evidence}/host-identity-and-versions.txt"
podman info --format json > "${evidence}/host-podman-info.json"
podman image inspect "${builder_image}" > "${evidence}/builder-image-inspect.json"
podman inspect "${container_id}" > "${evidence}/outer-container-inspect.json"

set +e
exec_output="$(devcontainer exec \
  --workspace-folder "${repo_dir}" \
  --config "${config}" \
  --docker-path podman \
  --mount-workspace-git-root=false \
  /usr/local/bin/test-nested-podman "${evidence_relative}" \
  2> "${evidence}/devcontainer-exec.stderr")"
exec_status=$?
set -e
printf '%s\n' "${exec_output}" > "${evidence}/devcontainer-exec.stdout"
printf '%s\n' "${exec_status}" > "${evidence}/devcontainer-exec.status"

if [[ ${exec_status} -ne 0 ]]; then
  fail 'Nested Podman smoke test failed; inspect .devcontainer/evidence.'
fi
[[ "${exec_output}" == 'nested podman ok' ]] || \
  fail 'Nested Podman smoke test emitted unexpected standard output.'

printf '%s\n' \
  'host-preflight=0' \
  "devcontainer-up=${up_status}" \
  'host-inspection=0' \
  "devcontainer-exec=${exec_status}" \
  > "${evidence}/host-command-statuses.txt"

printf 'nested podman ok\n'

#!/usr/bin/env bash
set -euo pipefail

readonly repo_dir="${PWD}"
readonly config="${repo_dir}/.devcontainer/devcontainer.json"
readonly subid_checker="${repo_dir}/.devcontainer/check-subordinate-id-range.sh"
readonly builder_image='registry.access.redhat.com/hi/core-runtime@sha256:32bfa924b015b66d61ba5450dc12f5a8693e32e8c38be8eb7c440395806f9ee7'
readonly run_id="${EPOCHSECONDS}-${$}"
readonly evidence_relative=".devcontainer/evidence/${run_id}"
readonly evidence="${repo_dir}/${evidence_relative}"

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

[[ "${EUID}" -ne 0 ]] || fail 'Run this recipe as a non-root host user.'
host_gid="$(id -g)"
readonly host_gid
host_user="$(id -un)"
readonly host_user
[[ "${host_gid}" -ne 0 ]] || fail 'Run this recipe with a non-root primary host GID.'
[[ "$(uname -m)" == x86_64 ]] || \
  fail 'Use or adapt the verified x86_64 host architecture.'
command -v devcontainer >/dev/null || fail 'Install the Dev Container CLI, then retry.'
command -v podman >/dev/null || fail 'Install rootless Podman, then retry.'
command -v just >/dev/null || fail 'Install Just, then retry.'
[[ "$(podman info --format '{{.Host.Security.Rootless}}')" == true ]] || \
  fail 'Configure Podman for the current non-root host user, then retry.'

bash "${repo_dir}/.devcontainer/test-subordinate-id-preflight.sh" "${repo_dir}"
host_subuid_range="$(
  bash "${subid_checker}" "${host_user}" "${EUID}" /etc/subuid subordinate-UID
)"
readonly host_subuid_range
host_subgid_range="$(
  bash "${subid_checker}" "${host_user}" "${EUID}" /etc/subgid subordinate-GID
)"
readonly host_subgid_range

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
    "devcontainer exec --workspace-folder ${repo_dir} --config ${config} --docker-path podman --mount-workspace-git-root=false /usr/local/bin/test-nested-podman ${evidence_relative}"
} > "${evidence}/host-commands.txt"

{
  id
  uname -a
  just --version
  devcontainer --version
  podman --version
  printf '%s\n' "current-user-subuid=${host_subuid_range}"
  printf '%s\n' "current-user-subgid=${host_subgid_range}"
  printf '%s\n' 'repository-revision=not-applicable-unversioned-staging'
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

#!/usr/bin/env bash
set -euo pipefail

readonly workspace="${PWD}"
readonly evidence_relative="${1:?evidence directory is required}"
readonly evidence="${workspace}/${evidence_relative}"
readonly baseline_evidence="${evidence_relative}/dynamic-uid-baseline"
readonly inner_source="${workspace}/inner-devcontainer"
readonly inner_workspace="/home/nonroot/.local/share/nested-podman/inner-devcontainer"
readonly inner_config="${inner_workspace}/.devcontainer/devcontainer.json"
readonly docker_path='/usr/local/bin/devcontainer-podman'
inner_container_id=''

cleanup() {
  if [[ -n "${inner_container_id}" ]]; then
    podman rm --force "${inner_container_id}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

install -d -m 0700 /dev/shm/nested-podman-build

baseline_output="$(/usr/local/bin/test-dynamic-podman "${baseline_evidence}")"
[[ "${baseline_output}" == 'nested podman ok' ]] || \
  fail 'The unchanged dynamic-UID nested Podman baseline failed.'
[[ "$(devcontainer --version)" == '0.88.0' ]] || \
  fail 'The outer container must provide Dev Container CLI 0.88.0.'

rm -rf "${inner_workspace}"
cp -a "${inner_source}" "${inner_workspace}"

cp /usr/local/share/nested-podman/devcontainer-cli-provenance.txt \
  "${evidence}/devcontainer-cli-provenance.txt"
podman ps --all --format '{{.ID}}\t{{.Names}}\t{{.Status}}' \
  > "${evidence}/cli-inner-containers-before.txt"

set +e
inner_up_output="$(devcontainer up \
  --workspace-folder "${inner_workspace}" \
  --config "${inner_config}" \
  --docker-path "${docker_path}" \
  --mount-workspace-git-root=false 2>&1)"
inner_up_status=$?
set -e
printf '%s\n' "${inner_up_output}" > "${evidence}/inner-devcontainer-up.log"
printf '%s\n' "${inner_up_status}" > "${evidence}/inner-devcontainer-up.status"

if [[ ${inner_up_status} -ne 0 ]]; then
  printf '%s\n' "${inner_up_output}" >&2
  fail 'The Dev Container CLI could not build and start the inner container.'
fi
if [[ ! "${inner_up_output}" =~ \"containerId\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
  fail 'The nested Dev Container CLI did not report the inner container identity.'
fi
inner_container_id="${BASH_REMATCH[1]}"
readonly inner_container_id

podman inspect "${inner_container_id}" \
  > "${evidence}/cli-inner-container-inspect.json"

set +e
smoke_output="$(devcontainer exec \
  --workspace-folder "${inner_workspace}" \
  --config "${inner_config}" \
  --docker-path "${docker_path}" \
  --mount-workspace-git-root=false \
  /bin/bash -c 'cat /tmp/runtime-echo.stdout')"
smoke_status=$?
set -e
printf '%s\n' "${smoke_output}" > "${evidence}/cli-smoke.stdout"
printf '%s\n' "${smoke_status}" > "${evidence}/cli-smoke.status"

podman rm --force "${inner_container_id}" \
  > "${evidence}/cli-inner-container-remove.txt"
podman ps --all --format '{{.ID}}\t{{.Names}}\t{{.Status}}' \
  > "${evidence}/cli-inner-containers-after.txt"
trap - EXIT

if [[ ${smoke_status} -ne 0 || "${smoke_output}" != 'nested podman ok' ]]; then
  fail 'The inner runtime echo failed or emitted unexpected standard output.'
fi

printf 'nested podman ok\n'

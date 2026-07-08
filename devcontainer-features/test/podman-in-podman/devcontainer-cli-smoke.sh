#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
workspace_dir="$(mktemp -d)"
feature_mount_dir="${workspace_dir}/.devcontainer"
config_file="${feature_mount_dir}/devcontainer.json"
feature_mount="${feature_mount_dir}/devcontainer-features"

cleanup() {
    local container_ids

    container_ids="$(docker ps -aq --filter "label=devcontainer.local_folder=${workspace_dir}" --filter "label=devcontainer.config_file=${config_file}")"
    if [ -n "${container_ids}" ]; then
        docker rm -f ${container_ids} >/dev/null
    fi

    rm -rf "${workspace_dir}"
}

trap cleanup EXIT

mkdir -p "${feature_mount_dir}"
ln -s "${repo_root}/src" "${feature_mount}"

cat >"${config_file}" <<'EOF'
{
  "name": "podman-in-podman-smoke",
  "image": "registry.access.redhat.com/hi/core-runtime:latest-builder",
  "remoteUser": "nonroot",
  "containerUser": "nonroot",
  "updateRemoteUserUID": false,
  "runArgs": [
    "--device=/dev/fuse",
    "--device=/dev/net/tun",
    "--security-opt=seccomp=unconfined"
  ],
  "overrideFeatureInstallOrder": [
    "./devcontainer-features/nonroot-user",
    "./devcontainer-features/podman-in-podman"
  ],
  "features": {
    "./devcontainer-features/nonroot-user": {
      "username": "nonroot"
    },
    "./devcontainer-features/podman-in-podman": {}
  },
  "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspaces/${localWorkspaceFolderBasename},type=bind,consistency=cached"
}
EOF

devcontainer up \
    --workspace-folder "${workspace_dir}" \
    --config "${config_file}" \
    --remove-existing-container \
    --skip-post-create >/dev/null

output="$(devcontainer exec --workspace-folder "${workspace_dir}" --config "${config_file}" sh -lc 'printf "hello world\n"')"
test "${output}" = "hello world"

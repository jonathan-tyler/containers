#!/usr/bin/env bash

set -euo pipefail

config=".devcontainer/devcontainer.json"

jq -e '.image == "registry.access.redhat.com/hi/core-runtime:latest-builder"' "${config}" >/dev/null
jq -e '.remoteUser == "developer" and .containerUser == "developer" and .updateRemoteUserUID == true' "${config}" >/dev/null
jq -e '.features == {"../devcontainer-features/podman-in-podman": {}}' "${config}" >/dev/null
jq -e 'has("build") | not' "${config}" >/dev/null
jq -e 'has("containerEnv") | not' "${config}" >/dev/null
jq -e 'has("customizations") | not' "${config}" >/dev/null
jq -e 'has("mounts") | not' "${config}" >/dev/null
jq -e '.workspaceFolder == "/workspaces/${localWorkspaceFolderBasename}"' "${config}" >/dev/null
jq -e '.workspaceMount == "source=${localWorkspaceFolder},target=/workspaces/${localWorkspaceFolderBasename},type=bind,consistency=cached"' "${config}" >/dev/null
jq -e '.runArgs | index("--userns=keep-id")' "${config}" >/dev/null
jq -e '.runArgs | index("--device=/dev/fuse")' "${config}" >/dev/null
jq -e '.runArgs | index("--security-opt=no-new-privileges")' "${config}" >/dev/null

echo "devcontainer config is aligned"

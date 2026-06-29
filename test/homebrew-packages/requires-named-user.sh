#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
feature_dir="${repo_root}/devcontainer-features/homebrew-packages"
log_file="$(mktemp)"
trap 'rm -f "${log_file}"' EXIT

if docker run --rm \
    --user root \
    -e _REMOTE_USER=65532 \
    -e _CONTAINER_USER=65532 \
    -e PACKAGES=hello \
    -e USERNAME=automatic \
    -v "${feature_dir}:/tmp/feature:ro" \
    --entrypoint /bin/sh \
    registry.access.redhat.com/hi/core-runtime:latest-builder \
    -lc 'cp -a /tmp/feature /tmp/feature-work && cd /tmp/feature-work && ./install.sh' >"${log_file}" 2>&1; then
    cat "${log_file}"
    echo "Expected homebrew-packages to reject numeric-only users." >&2
    exit 1
fi

grep -F "Homebrew requires a named non-root passwd user." "${log_file}" >/dev/null

#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
feature_dir="${repo_root}/src/homebrew-packages"
numeric_user_log_file="$(mktemp)"
automatic_user_log_file="$(mktemp)"
trap 'rm -f "${numeric_user_log_file}" "${automatic_user_log_file}"' EXIT

if docker run --rm \
    --user root \
    -e PACKAGES=hello \
    -e USERNAME=65532 \
    -v "${feature_dir}:/tmp/feature:ro" \
    --entrypoint /bin/sh \
    registry.access.redhat.com/hi/core-runtime:latest-builder \
    -lc 'cp -a /tmp/feature /tmp/feature-work && cd /tmp/feature-work && ./install.sh' >"${numeric_user_log_file}" 2>&1; then
    cat "${numeric_user_log_file}"
    echo "Expected homebrew-packages to reject numeric-only requested users." >&2
    exit 1
fi

grep -F "Requested user '65532' is numeric-only." "${numeric_user_log_file}" >/dev/null

if docker run --rm \
    --user root \
    -e _REMOTE_USER=65532 \
    -e _CONTAINER_USER=65532 \
    -e PACKAGES=hello \
    -e USERNAME=automatic \
    -v "${feature_dir}:/tmp/feature:ro" \
    --entrypoint /bin/sh \
    registry.access.redhat.com/hi/core-runtime:latest-builder \
    -lc 'cp -a /tmp/feature /tmp/feature-work && cd /tmp/feature-work && ./install.sh' >"${automatic_user_log_file}" 2>&1; then
    cat "${automatic_user_log_file}"
    echo "Expected homebrew-packages to reject automatic selection from UID 65532." >&2
    exit 1
fi

grep -F "Homebrew requires a named non-root passwd user." "${automatic_user_log_file}" >/dev/null

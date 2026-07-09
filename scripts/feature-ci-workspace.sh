#!/usr/bin/env bash

set -euo pipefail

copy_feature_tree=false
stamp_homebrew_base_image=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        --copy-feature-tree)
            copy_feature_tree=true
            shift
            ;;
        --stamp-homebrew-base-image)
            stamp_homebrew_base_image=true
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            break
            ;;
    esac
done

if [ "$#" -eq 0 ]; then
    printf 'usage: %s [--copy-feature-tree] [--stamp-homebrew-base-image] command [args...]\n' "$0" >&2
    exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "${script_dir}/.." && pwd)"
workspace_root="$(mktemp -d -t feature-ci.XXXXXX)"

cleanup() {
    local attempt=1

    while [ "${attempt}" -le 10 ]; do
        if rm -rf "${workspace_root}" >/dev/null 2>&1; then
            return
        fi
        attempt=$((attempt + 1))
        sleep 1
    done

    rm -rf "${workspace_root}" >/dev/null 2>&1 || true
}

trap cleanup EXIT

mkdir -p \
    "${workspace_root}/bin" \
    "${workspace_root}/package" \
    "${workspace_root}/tmp"

if [ "${copy_feature_tree}" = true ]; then
    "${project_root}/scripts/stage-feature-test-project.sh" "${project_root}/devcontainer-features" "${workspace_root}"
    "${project_root}/scripts/sync-homebrew-packages-additional.sh" "${workspace_root}/src/homebrew-packages" "${workspace_root}/src/homebrew-packages-additional"
    export FEATURE_PROJECT_DIR="${workspace_root}"
fi

export FEATURE_CI_WORKSPACE="${workspace_root}"
export TMPDIR="${workspace_root}/tmp"
export TMP="${workspace_root}/tmp"
export TEMP="${workspace_root}/tmp"

if [ "${stamp_homebrew_base_image}" = true ] && [ -z "${HOME_BREW_CI_BASE_IMAGE:-}" ]; then
    export HOME_BREW_CI_BASE_IMAGE="localhost/feature-ci/core-runtime:$(basename "${workspace_root}")"
fi

"$@"

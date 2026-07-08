#!/usr/bin/env bash

set -euo pipefail

unset GIT_DIR GIT_WORK_TREE

usage() {
    printf 'usage: %s [--repo-root <path>] [--staged | --compare-to <ref> [--head <ref>]]\n' "$0" >&2
}

die() {
    printf 'feature-version-bumps: %s\n' "$1" >&2
    exit 1
}

read_manifest_version() {
    local refspec="$1"
    local manifest_relpath="$2"

    if [ "$refspec" = ":" ]; then
        git show ":${manifest_relpath}" 2>/dev/null | jq -re '.version'
        return
    fi

    git show "${refspec}:${manifest_relpath}" 2>/dev/null | jq -re '.version'
}

repo_root=""
mode="staged"
compare_to=""
head_ref="HEAD"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --repo-root)
            repo_root="${2:?--repo-root requires a path}"
            shift 2
            ;;
        --staged)
            mode="staged"
            shift
            ;;
        --compare-to)
            compare_to="${2:?--compare-to requires a ref}"
            mode="compare"
            shift 2
            ;;
        --head)
            head_ref="${2:?--head requires a ref}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
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

if [ -z "$repo_root" ]; then
    repo_root="$(git rev-parse --show-toplevel)"
fi

if [ ! -d "$repo_root" ]; then
    die "repo root not found: ${repo_root}"
fi

repo_root="$(cd "$repo_root" && pwd -P)"
cd "$repo_root"

case "$mode" in
    staged)
        diff_cmd=(git diff --cached --name-only --diff-filter=ACMRD -- devcontainer-features/src)
        base_refspec="HEAD"
        current_refspec=":"
        current_refspec_label="index"
        ;;
    compare)
        if [ -z "$compare_to" ]; then
            die "compare mode requires a base ref"
        fi
        diff_cmd=(git diff --name-only --diff-filter=ACMRD "$compare_to" "$head_ref" -- devcontainer-features/src)
        base_refspec="$compare_to"
        current_refspec="$head_ref"
        current_refspec_label="$head_ref"
        ;;
    *)
        die "invalid mode: ${mode}"
        ;;
esac

declare -A feature_changed_files=()
declare -a changed_features=()

while IFS= read -r changed_path; do
    [ -n "$changed_path" ] || continue

    case "$changed_path" in
        devcontainer-features/src/*/*)
            feature_name="${changed_path#devcontainer-features/src/}"
            feature_name="${feature_name%%/*}"

            if [ -z "${feature_changed_files[$feature_name]+x}" ]; then
                changed_features+=("$feature_name")
                feature_changed_files["$feature_name"]=""
            fi

            feature_changed_files["$feature_name"]+="${changed_path}"$'\n'
            ;;
    esac
done < <("${diff_cmd[@]}")

if [ "${#changed_features[@]}" -eq 0 ]; then
    exit 0
fi

feature_root="$repo_root/devcontainer-features/src"

for feature_name in "${changed_features[@]}"; do
    feature_dir="$feature_root/$feature_name"
    manifest_relpath="devcontainer-features/src/${feature_name}/devcontainer-feature.json"

    if [ ! -f "$feature_dir/devcontainer-feature.json" ] && [ "$mode" = compare ]; then
        die "feature manifest missing for ${feature_dir}"
    fi

    if ! base_version="$(read_manifest_version "$base_refspec" "$manifest_relpath")"; then
        die "unable to read version from ${base_refspec}:${manifest_relpath}"
    fi

    if ! current_version="$(read_manifest_version "$current_refspec" "$manifest_relpath")"; then
        die "unable to read version from ${current_refspec_label}:${manifest_relpath}"
    fi

    if [ "$base_version" = "$current_version" ]; then
        printf 'feature-version-bumps: %s changed without a version bump\n' "$feature_dir" >&2
        printf '  version: %s\n' "$current_version" >&2
        printf '  changed files:\n' >&2
        while IFS= read -r changed_path; do
            [ -n "$changed_path" ] || continue
            printf '    - %s\n' "$changed_path" >&2
        done <<EOF
${feature_changed_files[$feature_name]}
EOF
        printf '  rerun: ./scripts/bump-feature-version.sh %s patch|minor|major|set X.Y.Z\n' "$feature_name" >&2
        exit 1
    fi
done

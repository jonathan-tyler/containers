#!/usr/bin/env bash

set -euo pipefail

unset GIT_DIR GIT_WORK_TREE

usage() {
    printf 'usage: %s [--repo-root <path>] [--dry-run] [--json] <feature-selector> <patch|minor|major|set> [version]\n' "$0" >&2
}

die() {
    printf 'feature-version-bump: %s\n' "$1" >&2
    exit 1
}

is_semver() {
    [[ "$1" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]
}

resolve_feature_dir() {
    local selector="$1"
    local -a candidates=()

    if [[ "$selector" = /* ]]; then
        candidates+=("$selector")
    elif [[ "$selector" == *"/"* ]]; then
        candidates+=("$selector" "$repo_root/$selector")
    else
        candidates+=("$repo_root/devcontainer-features/src/$selector" "$repo_root/$selector" "$selector")
    fi

    local candidate
    for candidate in "${candidates[@]}"; do
        if [ -d "$candidate" ] && [ -f "$candidate/devcontainer-feature.json" ]; then
            (cd "$candidate" && pwd -P)
            return 0
        fi
    done

    return 1
}

repo_root=""
dry_run=false
json=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        --repo-root)
            repo_root="${2:?--repo-root requires a path}"
            shift 2
            ;;
        --dry-run)
            dry_run=true
            shift
            ;;
        --json)
            json=true
            shift
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

selector="${1:-}"
directive="${2:-}"

if [ -z "$selector" ] || [ -z "$directive" ]; then
    usage
    exit 1
fi

case "$directive" in
    patch|minor|major)
        if [ "$#" -ne 2 ]; then
            usage
            exit 1
        fi
        bump_target=""
        ;;
    set)
        if [ "$#" -ne 3 ]; then
            usage
            exit 1
        fi
        bump_target="${3:?set requires a semantic version}"
        ;;
    *)
        die "invalid bump directive: ${directive}"
        ;;
esac

if [ -z "$repo_root" ]; then
    repo_root="$(git rev-parse --show-toplevel)"
fi

if [ ! -d "$repo_root" ]; then
    die "repo root not found: ${repo_root}"
fi

repo_root="$(cd "$repo_root" && pwd -P)"
feature_dir="$(resolve_feature_dir "$selector" || true)"

if [ -z "$feature_dir" ]; then
    die "unable to resolve feature selector: ${selector}"
fi

manifest_path="$feature_dir/devcontainer-feature.json"
feature_name="$(basename "$feature_dir")"

current_version="$(jq -re '.version' "$manifest_path")"
if ! is_semver "$current_version"; then
    die "current version in ${manifest_path} is not semantic version: ${current_version}"
fi

major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"

case "$directive" in
    patch)
        new_version="${major}.${minor}.$((patch + 1))"
        ;;
    minor)
        new_version="${major}.$((minor + 1)).0"
        ;;
    major)
        new_version="$((major + 1)).0.0"
        ;;
    set)
        new_version="$bump_target"
        if ! is_semver "$new_version"; then
            die "set target is not semantic version: ${new_version}"
        fi
        ;;
esac

if [ "$json" = true ]; then
    if [ "$dry_run" = true ]; then
        jq -n \
            --arg feature "$feature_name" \
            --arg manifest "$manifest_path" \
            --arg current_version "$current_version" \
            --arg new_version "$new_version" \
            --argjson dry_run true \
            '{feature: $feature, manifest: $manifest, current_version: $current_version, new_version: $new_version, dry_run: $dry_run}'
        exit 0
    fi

    tmp_manifest="$(mktemp)"
    jq --arg version "$new_version" '.version = $version' "$manifest_path" > "$tmp_manifest"
    mv "$tmp_manifest" "$manifest_path"

    jq -n \
        --arg feature "$feature_name" \
        --arg manifest "$manifest_path" \
        --arg current_version "$current_version" \
        --arg new_version "$new_version" \
        --argjson dry_run false \
        '{feature: $feature, manifest: $manifest, current_version: $current_version, new_version: $new_version, dry_run: $dry_run}'
    exit 0
fi

if [ "$dry_run" = true ]; then
    printf '%s: %s -> %s (dry run)\n' "$feature_name" "$current_version" "$new_version"
    exit 0
fi

tmp_manifest="$(mktemp)"
jq --arg version "$new_version" '.version = $version' "$manifest_path" > "$tmp_manifest"
mv "$tmp_manifest" "$manifest_path"

printf '%s: %s -> %s\n' "$feature_name" "$current_version" "$new_version"

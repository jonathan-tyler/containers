#!/usr/bin/env bash

set -euo pipefail

# Generate the publish-only alias feature from the primary Homebrew feature.
# The repo keeps `homebrew-packages` as the source of truth and mirrors it here
# so local packaging and the GitHub release workflow can publish both names.
source_dir="${1:?source feature directory required}"
target_dir="${2:?target feature directory required}"

if [ ! -d "${source_dir}" ]; then
    echo "(!) Source feature directory not found: ${source_dir}" >&2
    exit 1
fi

rm -rf "${target_dir}"
cp -a "${source_dir}" "${target_dir}"

# Rewrite every copied file except the manifest first so the alias content stays
# in sync with the primary feature without accidentally rewriting the new ID.
while IFS= read -r -d '' file; do
    if [ "${file}" = "${target_dir}/devcontainer-feature.json" ]; then
        continue
    fi

    perl -0pi -e 's/homebrew-packages/homebrew-packages-additional/g' "${file}"
done < <(find "${target_dir}" -type f -print0)

jq '.id = "homebrew-packages-additional" | .name = "Homebrew Packages Additional"' \
    "${target_dir}/devcontainer-feature.json" > "${target_dir}/devcontainer-feature.json.tmp"
mv "${target_dir}/devcontainer-feature.json.tmp" "${target_dir}/devcontainer-feature.json"

# Keep the generated README title aligned with the published alias name.
perl -0pi -e 's/^# Homebrew Packages /# Homebrew Packages Additional /m' \
    "${target_dir}/README.md"

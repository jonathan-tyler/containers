#!/usr/bin/env bash

set -euo pipefail

source_dir="${1:?source feature directory required}"
target_dir="${2:?target feature directory required}"

if [ ! -d "${source_dir}" ]; then
    echo "(!) Source feature directory not found: ${source_dir}" >&2
    exit 1
fi

rm -rf "${target_dir}"
cp -a "${source_dir}" "${target_dir}"

while IFS= read -r -d '' file; do
    if [ "${file}" = "${target_dir}/devcontainer-feature.json" ]; then
        continue
    fi

    perl -0pi -e 's/homebrew-packages/homebrew-packages-additional/g' "${file}"
done < <(find "${target_dir}" -type f -print0)

jq '.id = "homebrew-packages-additional" | .name = "Homebrew Packages Additional"' \
    "${target_dir}/devcontainer-feature.json" > "${target_dir}/devcontainer-feature.json.tmp"
mv "${target_dir}/devcontainer-feature.json.tmp" "${target_dir}/devcontainer-feature.json"

perl -0pi -e 's/^# Homebrew Packages /# Homebrew Packages Additional /m' \
    "${target_dir}/README.md"

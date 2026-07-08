#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 2 ]; then
    printf 'usage: %s <source-project-dir> <staged-project-dir>\n' "$0" >&2
    exit 1
fi

source_project_dir="$1"
staged_project_dir="$2"

mkdir -p "${staged_project_dir}/src" "${staged_project_dir}/test"
cp -a "${source_project_dir}/src/." "${staged_project_dir}/src"
cp -a "${source_project_dir}/test/." "${staged_project_dir}/test"

for feature_test_dir in "${source_project_dir}"/test/*; do
    [ -d "${feature_test_dir}" ] || continue

    feature_name="$(basename "${feature_test_dir}")"
    staged_feature_test_dir="${staged_project_dir}/src/${feature_name}/test"
    mkdir -p "${staged_feature_test_dir}"
    cp -a "${feature_test_dir}/." "${staged_feature_test_dir}"

    # Scenario scripts run from .devcontainer/<feature>/test, but the CLI writes
    # its shared test library at the workspace root.
    cat <<'EOF' > "${staged_feature_test_dir}/dev-container-features-test-lib"
. ../../../dev-container-features-test-lib
EOF
done

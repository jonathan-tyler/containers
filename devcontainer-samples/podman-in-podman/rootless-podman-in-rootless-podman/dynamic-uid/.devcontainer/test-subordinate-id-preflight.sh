#!/usr/bin/env bash
set -euo pipefail

readonly workspace="${1:?workspace is required}"
readonly checker="${workspace}/.devcontainer/check-subordinate-id-range.sh"
fixture_dir="$(mktemp -d "${workspace}/.devcontainer/.subid-test.XXXXXX")"
readonly fixture_dir
trap 'rm -rf "${fixture_dir}"' EXIT

check_accepts() {
  local expected="$1"
  local fixture="$2"
  local actual

  actual="$(bash "${checker}" developer 4242 "${fixture}" subordinate-test)"
  [[ "${actual}" == "${expected}" ]]
}

check_rejects() {
  local fixture="$1"

  ! bash "${checker}" developer 4242 "${fixture}" subordinate-test \
    >/dev/null 2>&1
}

printf '%s\n' 'developer:700000:65536' > "${fixture_dir}/arbitrary-start"
check_accepts '700000:65536' "${fixture_dir}/arbitrary-start"

printf '%s\n' '4242:900000:70000' > "${fixture_dir}/numeric-owner"
check_accepts '900000:70000' "${fixture_dir}/numeric-owner"

printf '%s\n' 'someone-else:100000:65536' > "${fixture_dir}/missing"
check_rejects "${fixture_dir}/missing"

printf '%s\n' 'developer:100000:32768' 'developer:200000:32768' \
  > "${fixture_dir}/fragmented"
check_rejects "${fixture_dir}/fragmented"

printf '%s\n' 'developer:100000:65535' > "${fixture_dir}/undersized"
check_rejects "${fixture_dir}/undersized"

printf '%s\n' 'developer:100000:not-a-count' > "${fixture_dir}/malformed"
check_rejects "${fixture_dir}/malformed"

printf '%s\n' 'developer:100000:999999999999999999999999999999999999' \
  > "${fixture_dir}/large-count"
check_accepts '100000:999999999999999999999999999999999999' \
  "${fixture_dir}/large-count"

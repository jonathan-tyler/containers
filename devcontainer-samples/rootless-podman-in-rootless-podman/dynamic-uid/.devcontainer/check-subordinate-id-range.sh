#!/usr/bin/env bash
set -euo pipefail

readonly account_name="${1:?account name is required}"
readonly account_id="${2:?account ID is required}"
readonly ranges_file="${3:?subordinate-ID file is required}"
readonly id_kind="${4:?ID kind is required}"
readonly minimum_count=65536

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

decimal_is_at_least() {
  local value="$1"
  local minimum="$2"

  while [[ "${value}" == 0* && ${#value} -gt 1 ]]; do
    value="${value#0}"
  done
  if (( ${#value} != ${#minimum} )); then
    (( ${#value} > ${#minimum} ))
    return
  fi
  [[ "${value}" == "${minimum}" || "${value}" > "${minimum}" ]]
}

[[ -r "${ranges_file}" ]] || \
  fail "The host ${id_kind} ranges are not readable. Ask the host owner to inspect ${ranges_file}."

matches=()
while IFS=: read -r owner start count extra; do
  [[ "${owner}" == "${account_name}" || "${owner}" == "${account_id}" ]] || continue
  [[ -z "${extra}" && "${start}" =~ ^[0-9]+$ && "${count}" =~ ^[0-9]+$ ]] || \
    fail "The host ${id_kind} range entry is malformed. Ask the host owner to inspect ${ranges_file}."
  matches+=("${start}:${count}")
done < "${ranges_file}"

if (( ${#matches[@]} == 0 )); then
  fail "No host ${id_kind} range was found. Ask the host owner to assign one contiguous range of at least ${minimum_count} IDs."
fi
if (( ${#matches[@]} != 1 )); then
  fail "Fragmented host ${id_kind} ranges are unsupported. Ask the host owner whether they can provide one contiguous range of at least ${minimum_count} IDs."
fi

IFS=: read -r range_start range_count <<< "${matches[0]}"
if ! decimal_is_at_least "${range_count}" "${minimum_count}"; then
  fail "The host ${id_kind} range is undersized. Ask the host owner whether they can provide one contiguous range of at least ${minimum_count} IDs."
fi

printf '%s:%s\n' "${range_start}" "${range_count}"

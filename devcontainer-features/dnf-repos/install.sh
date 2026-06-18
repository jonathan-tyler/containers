#!/usr/bin/env bash

set -euo pipefail

err() {
    echo "(!) $*" >&2
}

if [ "$(id -u)" -ne 0 ]; then
    err "Script must be run as root. Use sudo, su, or add 'USER root' to your Dockerfile before running this script."
    exit 1
fi

if ! command -v dnf >/dev/null 2>&1; then
    err "This feature currently supports Fedora and RHEL-family images with dnf."
    exit 1
fi

enabled_repo_ids="$(dnf -q repolist --enabled | awk '
    /^repo[[:space:]]+id[[:space:]]+repo[[:space:]]+name/ { header_seen=1; next }
    header_seen && $1 ~ /^[[:alnum:]_.+-]+$/ { print $1 }
')"

if [ "$(printf '%s\n' "${enabled_repo_ids}" | awk 'NF { count++ } END { print count + 0 }')" -ne 1 ] || ! printf '%s\n' "${enabled_repo_ids}" | grep -qx "hummingbird"; then
    echo "DNF repo fallback not needed; leaving existing repos unchanged."
    exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
    dnf -y --setopt=install_weak_deps=False install jq
fi

rendered_repos="$(printf '%s' "${REPOS_JSON:-[]}" | jq -r '
    def fail($msg): error($msg);

    def as_int($field):
        if type == "boolean" then if . then 1 else 0 end
        elif type == "number" and floor == . then .
        elif type == "string" and test("^[0-9]+$") then tonumber
        else fail("Repo field \($field) must be an integer or boolean value.")
        end;

    def as_text($field):
        if type == "string" and length > 0 then .
        else fail("Repo field \($field) must be a non-empty string.")
        end;

    def as_list_or_text($field):
        if type == "string" and length > 0 then .
        elif type == "array" and length > 0 and all(.[]; type == "string" and length > 0) then join(",")
        else fail("Repo field \($field) must be a non-empty string or a non-empty list of strings.")
        end;

    def normalize:
        if type != "object" then fail("Each repo definition must be a JSON object.") else . end
        | .id as $id
        | if ($id | type != "string" or length == 0) then fail("Repo field 'id' must be a non-empty string.") else . end
        | if ($id | test("[/\\\\]")) then fail("Repo id must not contain path separators.") else . end
        | (keys - ["baseurl", "cost", "enabled", "excludepkgs", "gpgcheck", "gpgkey", "id", "includepkgs", "metadata_expire", "metalink", "mirrorlist", "module_hotfixes", "name", "priority", "repo_gpgcheck", "skip_if_unavailable", "type"]) as $unknown
        | if ($unknown | length) > 0 then fail("Repo \($id) contains unsupported field(s): \($unknown | join(", "))") else . end
        | ([has("baseurl"), has("metalink"), has("mirrorlist")] | map(select(.)) | length) as $source_count
        | if $source_count != 1 then fail("Repo \($id) must define exactly one of baseurl, metalink, or mirrorlist.") else . end
        | {
            id: $id,
            name: ((.name // $id) | as_text("name")),
            source_field: (if has("baseurl") and .baseurl != null and .baseurl != "" then "baseurl" elif has("metalink") and .metalink != null and .metalink != "" then "metalink" else "mirrorlist" end),
            source_value: (if has("baseurl") and .baseurl != null and .baseurl != "" then (.baseurl | as_text("baseurl")) elif has("metalink") and .metalink != null and .metalink != "" then (.metalink | as_text("metalink")) else (.mirrorlist | as_text("mirrorlist")) end),
            enabled: ((.enabled // 1) | as_int("enabled") | tostring),
            gpgcheck: ((.gpgcheck // 1) | as_int("gpgcheck") | tostring),
            repo_gpgcheck: ((.repo_gpgcheck // 0) | as_int("repo_gpgcheck") | tostring),
            priority: (if has("priority") and .priority != null then (.priority | as_int("priority") | tostring) else "" end),
            gpgkey: (if has("gpgkey") and .gpgkey != null then (.gpgkey | as_text("gpgkey")) else "" end),
            skip_if_unavailable: (if has("skip_if_unavailable") and .skip_if_unavailable != null then (.skip_if_unavailable | as_int("skip_if_unavailable") | tostring) else "" end),
            cost: (if has("cost") and .cost != null then (.cost | as_int("cost") | tostring) else "" end),
            module_hotfixes: (if has("module_hotfixes") and .module_hotfixes != null then (.module_hotfixes | as_int("module_hotfixes") | tostring) else "" end),
            metadata_expire: (if has("metadata_expire") and .metadata_expire != null then (.metadata_expire | as_text("metadata_expire")) else "" end),
            type: (if has("type") and .type != null then (.type | as_text("type")) else "" end),
            includepkgs: (if has("includepkgs") and .includepkgs != null then (.includepkgs | as_list_or_text("includepkgs")) else "" end),
            excludepkgs: (if has("excludepkgs") and .excludepkgs != null then (.excludepkgs | as_list_or_text("excludepkgs")) else "" end)
          };

    if type != "array" then fail("REPOS_JSON must decode to a JSON array.") else . end
    | map(normalize) as $repos
    | if ($repos | map(.id) | length) != ($repos | map(.id) | unique | length) then fail("REPOS_JSON contains duplicate repo ids.") else $repos end
    | if length == 0 then empty else .[] end
    | [
        .id,
        .name,
        .source_field,
        .source_value,
        .enabled,
        .gpgcheck,
        .repo_gpgcheck,
        .priority,
        .gpgkey,
        .skip_if_unavailable,
        .cost,
        .module_hotfixes,
        .metadata_expire,
        .type,
        .includepkgs,
        .excludepkgs
      ] | @tsv
')"

if [ -z "${rendered_repos}" ]; then
    echo "No repo definitions provided; nothing to write."
    exit 0
fi

mkdir -p /etc/yum.repos.d

while IFS=$'\t' read -r repo_id repo_name source_field source_value enabled gpgcheck repo_gpgcheck priority gpgkey skip_if_unavailable cost module_hotfixes metadata_expire repo_type includepkgs excludepkgs; do
    repo_path="/etc/yum.repos.d/${repo_id}.repo"

    {
        printf '[%s]\n' "${repo_id}"
        printf 'name=%s\n' "${repo_name}"
        printf '%s=%s\n' "${source_field}" "${source_value}"
        printf 'enabled=%s\n' "${enabled}"
        printf 'gpgcheck=%s\n' "${gpgcheck}"
        printf 'repo_gpgcheck=%s\n' "${repo_gpgcheck}"

        if [ -n "${priority}" ]; then printf 'priority=%s\n' "${priority}"; fi
        if [ -n "${gpgkey}" ]; then printf 'gpgkey=%s\n' "${gpgkey}"; fi
        if [ -n "${skip_if_unavailable}" ]; then printf 'skip_if_unavailable=%s\n' "${skip_if_unavailable}"; fi
        if [ -n "${cost}" ]; then printf 'cost=%s\n' "${cost}"; fi
        if [ -n "${module_hotfixes}" ]; then printf 'module_hotfixes=%s\n' "${module_hotfixes}"; fi
        if [ -n "${metadata_expire}" ]; then printf 'metadata_expire=%s\n' "${metadata_expire}"; fi
        if [ -n "${repo_type}" ]; then printf 'type=%s\n' "${repo_type}"; fi
        if [ -n "${includepkgs}" ]; then printf 'includepkgs=%s\n' "${includepkgs}"; fi
        if [ -n "${excludepkgs}" ]; then printf 'excludepkgs=%s\n' "${excludepkgs}"; fi
    } >"${repo_path}"
done <<< "${rendered_repos}"

dnf clean all

echo "Wrote repo file(s) to /etc/yum.repos.d."
echo "Done!"

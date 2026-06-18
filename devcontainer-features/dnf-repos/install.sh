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

if ! command -v python3 >/dev/null 2>&1; then
    err "This feature requires python3 to parse REPOS_JSON."
    exit 1
fi

python3 - "${REPOS_JSON:-[]}" <<'PY'
import json
import pathlib
import re
import subprocess
import sys

RAW_REPOS = sys.argv[1]
REPO_DIR = pathlib.Path("/etc/yum.repos.d")
PRIMARY_REPO_ID = "hummingbird"
ALLOWED_FIELDS = {
    "baseurl",
    "cost",
    "enabled",
    "excludepkgs",
    "gpgcheck",
    "gpgkey",
    "id",
    "includepkgs",
    "metadata_expire",
    "metalink",
    "mirrorlist",
    "module_hotfixes",
    "name",
    "priority",
    "repo_gpgcheck",
    "skip_if_unavailable",
    "type",
}


def fail(message: str) -> None:
    print(f"(!) {message}", file=sys.stderr)
    raise SystemExit(1)


def as_int(value, field: str) -> int:
    if isinstance(value, bool):
        return int(value)
    if isinstance(value, int):
        return value
    if isinstance(value, str) and value.strip().isdigit():
        return int(value)
    fail(f"Repo field '{field}' must be an integer or boolean value.")


def as_text(value, field: str) -> str:
    if isinstance(value, str) and value.strip():
        return value
    fail(f"Repo field '{field}' must be a non-empty string.")


def as_list_or_text(value, field: str) -> str:
    if isinstance(value, str) and value.strip():
        return value
    if isinstance(value, list) and value and all(isinstance(item, str) and item.strip() for item in value):
        return ",".join(item.strip() for item in value)
    fail(f"Repo field '{field}' must be a non-empty string or a non-empty list of strings.")


def enabled_repo_ids() -> list[str]:
    try:
        result = subprocess.run(
            ["dnf", "-q", "repolist", "--enabled"],
            check=True,
            text=True,
            capture_output=True,
        )
    except subprocess.CalledProcessError as exc:
        output = (exc.stderr or exc.stdout or "").strip()
        if output:
            fail(f"Unable to read enabled repos: {output}")
        fail("Unable to read enabled repos.")

    repo_ids: list[str] = []
    header_seen = False
    for line in result.stdout.splitlines():
        if re.match(r"^repo\s+id\s+repo\s+name$", line.strip()):
            header_seen = True
            continue
        if header_seen:
            match = re.match(r"^([A-Za-z0-9_.+-]+)\s+", line)
            if match:
                repo_ids.append(match.group(1))
    return repo_ids


def normalize_repo(repo: dict) -> dict:
    if not isinstance(repo, dict):
        fail("Each repo definition must be a JSON object.")

    repo_id = as_text(repo.get("id"), "id")
    if any(ch in repo_id for ch in "/\\"):
        fail("Repo id must not contain path separators.")

    unknown_fields = sorted(set(repo) - ALLOWED_FIELDS)
    if unknown_fields:
        fail(f"Repo '{repo_id}' contains unsupported field(s): {', '.join(unknown_fields)}")

    sources = [field for field in ("baseurl", "metalink", "mirrorlist") if field in repo and repo[field] not in (None, "")]
    if len(sources) != 1:
        fail(f"Repo '{repo_id}' must define exactly one of baseurl, metalink, or mirrorlist.")

    normalized = {
        "id": repo_id,
        "name": as_text(repo.get("name", repo_id), "name"),
        "source_field": sources[0],
        "source_value": as_text(repo[sources[0]], sources[0]),
        "enabled": as_int(repo.get("enabled", 1), "enabled"),
        "gpgcheck": as_int(repo.get("gpgcheck", 1), "gpgcheck"),
        "repo_gpgcheck": as_int(repo.get("repo_gpgcheck", 0), "repo_gpgcheck"),
    }

    for field in ("priority", "cost", "module_hotfixes", "skip_if_unavailable"):
        if field in repo and repo[field] is not None:
            normalized[field] = as_int(repo[field], field)

    for field in ("gpgkey", "metadata_expire", "type"):
        if field in repo and repo[field] is not None:
            normalized[field] = as_text(repo[field], field)

    for field in ("includepkgs", "excludepkgs"):
        if field in repo and repo[field] is not None:
            normalized[field] = as_list_or_text(repo[field], field)

    return normalized


try:
    parsed = json.loads(RAW_REPOS)
except json.JSONDecodeError as exc:
    fail(f"REPOS_JSON is not valid JSON: {exc.msg} (line {exc.lineno}, column {exc.colno})")

if not isinstance(parsed, list):
    fail("REPOS_JSON must decode to a JSON array.")

repos = [normalize_repo(repo) for repo in parsed]
repo_ids = [repo["id"] for repo in repos]
if len(repo_ids) != len(set(repo_ids)):
    fail("REPOS_JSON contains duplicate repo ids.")

enabled_ids = enabled_repo_ids()
if len(enabled_ids) != 1 or enabled_ids[0] != PRIMARY_REPO_ID:
    print("DNF repo fallback not needed; leaving existing repos unchanged.")
    raise SystemExit(0)

if not repos:
    print("No repo definitions provided; nothing to write.")
    raise SystemExit(0)

REPO_DIR.mkdir(parents=True, exist_ok=True)

for repo in repos:
    repo_path = REPO_DIR / f"{repo['id']}.repo"
    lines = [
        f"[{repo['id']}]",
        f"name={repo['name']}",
        f"{repo['source_field']}={repo['source_value']}",
        f"enabled={repo['enabled']}",
        f"gpgcheck={repo['gpgcheck']}",
        f"repo_gpgcheck={repo['repo_gpgcheck']}",
    ]

    for field in ("priority", "gpgkey", "skip_if_unavailable", "cost", "module_hotfixes", "metadata_expire", "type", "includepkgs", "excludepkgs"):
        if field in repo:
            lines.append(f"{field}={repo[field]}")

    repo_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

print(f"Wrote {len(repos)} repo file(s) to {REPO_DIR}.")
PY

echo "Done!"

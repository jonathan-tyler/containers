#!/usr/bin/env bash

set -euo pipefail

FEDORA_RELEASE="42"
FEDORA_REPO_PRIORITY="99"
FEDORA_REPO_ID="fedora"
HUMMINGBIRD_REPO_ID="hummingbird"

err() {
    echo "(!) $*" >&2
}

enabled_repo_ids() {
    dnf -q repolist --enabled | awk '
        /^repo[[:space:]]+id[[:space:]]+repo[[:space:]]+name/ { header_seen=1; next }
        header_seen && $1 ~ /^[[:alnum:]_.+-]+$/ { print $1 }
    '
}

should_write_fedora_repo() {
    local repo_ids
    local repo_count

    repo_ids="$(enabled_repo_ids)"
    repo_count="$(printf '%s\n' "${repo_ids}" | awk 'NF { count++ } END { print count + 0 }')"

    if [ "${repo_count}" -ne 1 ]; then
        return 1
    fi

    printf '%s\n' "${repo_ids}" | grep -qx "${HUMMINGBIRD_REPO_ID}"
}

if [ "$(id -u)" -ne 0 ]; then
    err "Script must be run as root. Use sudo, su, or add 'USER root' to your Dockerfile before running this script."
    exit 1
fi

if ! command -v dnf >/dev/null 2>&1; then
    err "This feature currently supports Fedora and RHEL-family images with dnf."
    exit 1
fi

if ! should_write_fedora_repo; then
    echo "Fedora fallback not needed; leaving existing repos unchanged."
    exit 0
fi

mkdir -p /etc/yum.repos.d

cat >/etc/yum.repos.d/fedora.repo <<EOF
[${FEDORA_REPO_ID}]
name=Fedora ${FEDORA_RELEASE} - \$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-${FEDORA_RELEASE}&arch=\$basearch
enabled=1
metadata_expire=7d
type=rpm-md
priority=${FEDORA_REPO_PRIORITY}
repo_gpgcheck=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-${FEDORA_RELEASE}-\$basearch
EOF

echo "Wrote Fedora fallback repo to /etc/yum.repos.d/fedora.repo"
echo "Done!"

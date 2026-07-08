#!/usr/bin/env bash

HUMMINGBIRD_REPO_ID="public-hummingbird-x86_64-rpms"
FEDORA_RELEASE="42"
FEDORA_REPO_FILE="/etc/yum.repos.d/podman-in-podman-fedora.repo"
USED_DNF=0

dnfRepoExists() {
    local repo_id="$1"

    dnf repolist --all 2>/dev/null | grep -qE "^${repo_id}[[:space:]]"
}

installFedoraRhelPackages() {
    if [ "$#" -eq 0 ]; then
        return
    fi

    if ! commandExists dnf; then
        err "Missing Podman prerequisites ($*) and no dnf package manager is available to install them."
        exit 1
    fi

    if dnfRepoExists "${HUMMINGBIRD_REPO_ID}"; then
        if dnf -y install --disablerepo='*' --enablerepo="${HUMMINGBIRD_REPO_ID}" --setopt=install_weak_deps=False "$@"; then
            USED_DNF=1
            return
        fi

        if hasEnabledDnfRepoBesides "${HUMMINGBIRD_REPO_ID}"; then
            dnf -y --disablerepo="${HUMMINGBIRD_REPO_ID}" --setopt=install_weak_deps=False install "$@"
            USED_DNF=1
            return
        fi

        installWithTemporaryFedoraFallback "$@"
        USED_DNF=1
        return
    fi

    dnf -y install --setopt=install_weak_deps=False "$@"
    USED_DNF=1
}

installPodmanPackagesIfNeeded() {
    local packages=()

    if ! commandExists podman; then
        packages+=(
            ca-certificates
            containernetworking-plugins
            fuse-overlayfs
            podman
            slirp4netns
            shadow-utils-subid
        )
    else
        if ! commandExists fuse-overlayfs; then
            packages+=(fuse-overlayfs)
        fi
        if ! commandExists slirp4netns; then
            packages+=(slirp4netns)
        fi
        if ! commandExists newuidmap || ! commandExists newgidmap; then
            packages+=(shadow-utils-subid)
        fi
    fi

    installFedoraRhelPackages "${packages[@]}"
}

cleanupFedoraRhelPackages() {
    rm -f "${FEDORA_REPO_FILE}"

    if [ "${USED_DNF}" = "1" ]; then
        dnf clean all
    fi
}

hasEnabledDnfRepoBesides() {
    local ignored_repo_id="$1"
    local repo_lines
    local line
    local repo_id

    repo_lines="$(dnf repolist --enabled 2>/dev/null | grep -E '^[[:alnum:]_.:-]+[[:space:]]' || true)"

    while IFS= read -r line; do
        [ -n "${line}" ] || continue
        repo_id="${line%%[[:space:]]*}"
        if [ "${repo_id}" = "repo" ]; then
            continue
        fi
        if [ -n "${repo_id}" ] && [ "${repo_id}" != "${ignored_repo_id}" ]; then
            return 0
        fi
    done <<EOF
${repo_lines}
EOF

    return 1
}

writeTemporaryFedoraRepos() {
    local gpgcheck="$1"

    cat >"${FEDORA_REPO_FILE}" <<EOF
[fedora]
name=Fedora ${FEDORA_RELEASE} - \$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-${FEDORA_RELEASE}&arch=\$basearch
enabled=1
metadata_expire=7d
type=rpm-md
gpgcheck=${gpgcheck}
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-${FEDORA_RELEASE}-\$basearch

[updates]
name=Fedora ${FEDORA_RELEASE} - \$basearch - Updates
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f${FEDORA_RELEASE}&arch=\$basearch
enabled=1
metadata_expire=6h
type=rpm-md
gpgcheck=${gpgcheck}
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-${FEDORA_RELEASE}-\$basearch
EOF
}

installWithTemporaryFedoraFallback() {
    writeTemporaryFedoraRepos 0
    dnf -y --setopt=install_weak_deps=False install fedora-gpg-keys
    writeTemporaryFedoraRepos 1
    dnf -y --disablerepo="${HUMMINGBIRD_REPO_ID}" --setopt=install_weak_deps=False install "$@"
}

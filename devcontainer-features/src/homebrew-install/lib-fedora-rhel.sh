#!/usr/bin/env bash

installFedoraRhelPackages() {
    if [ "$#" -eq 0 ]; then
        return
    fi

    if ! commandExists dnf; then
        err "Missing Homebrew prerequisites ($*) and no dnf package manager is available to install them."
        exit 1
    fi

    dnf -y install --setopt=install_weak_deps=False ca-certificates "$@"
    dnf clean all
}

ensureHomebrewPrerequisites() {
    local missing_packages=()

    requireHomebrewGlibcAtLeast239
    installFedoraRhelPackages gcc gcc-c++ glibc-devel libstdc++-devel make patch

    if ! commandExists bash; then
        missing_packages+=(bash)
    fi

    if ! commandExists curl; then
        missing_packages+=(curl)
    fi

    if ! commandExists git; then
        missing_packages+=(git)
    fi

    if ! commandExists file; then
        missing_packages+=(file)
    fi

    if ! commandExists awk; then
        missing_packages+=(gawk)
    fi

    if ! commandExists ps; then
        missing_packages+=(procps-ng)
    fi

    if ! commandExists tar; then
        missing_packages+=(tar)
    fi

    if ! commandExists gzip; then
        missing_packages+=(gzip)
    fi

    if ! commandExists xz; then
        missing_packages+=(xz)
    fi

    installFedoraRhelPackages "${missing_packages[@]}"
    requireHomebrewPrerequisiteCommands
}

ensureUserSwitchTool() {
    if commandExists runuser || commandExists su || commandExists setpriv; then
        return
    fi

    installFedoraRhelPackages util-linux

    if ! commandExists runuser && ! commandExists su && ! commandExists setpriv; then
        err "Installing Homebrew as a non-root user requires runuser, su, or setpriv."
        exit 1
    fi
}

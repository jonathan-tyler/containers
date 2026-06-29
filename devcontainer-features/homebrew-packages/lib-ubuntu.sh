#!/usr/bin/env bash

installUbuntuPackages() {
    if [ "$#" -eq 0 ]; then
        return
    fi

    if ! commandExists apt-get; then
        err "Missing Homebrew prerequisites ($*) and no apt-get package manager is available to install them."
        exit 1
    fi

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends ca-certificates "$@"
    rm -rf /var/lib/apt/lists/*
}

ensureHomebrewPrerequisites() {
    local missing_packages=()

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
        missing_packages+=(procps)
    fi

    if ! commandExists tar; then
        missing_packages+=(tar)
    fi

    if ! commandExists gzip; then
        missing_packages+=(gzip)
    fi

    if ! commandExists xz; then
        missing_packages+=(xz-utils)
    fi

    installUbuntuPackages "${missing_packages[@]}"
    requireHomebrewPrerequisiteCommands
}

ensureUserSwitchTool() {
    if commandExists runuser || commandExists su || commandExists setpriv; then
        return
    fi

    installUbuntuPackages util-linux

    if ! commandExists runuser && ! commandExists su && ! commandExists setpriv; then
        err "Installing formulae as a non-root user requires runuser, su, or setpriv."
        exit 1
    fi
}

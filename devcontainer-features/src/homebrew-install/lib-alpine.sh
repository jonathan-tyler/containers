#!/usr/bin/env bash

alpineUnsupported() {
    err "Homebrew upstream does not currently support Alpine's musl base for this feature. The installer requires glibc-backed portable Ruby or a system Ruby 4.0, which plain Alpine images do not provide. Use an Ubuntu or RHEL-family image instead."
    exit 1
}

ensureHomebrewPrerequisites() {
    alpineUnsupported
}

ensureUserSwitchTool() {
    alpineUnsupported
}

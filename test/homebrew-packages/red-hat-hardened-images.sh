#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

# Podman injects passwd entries for numeric users by default, but Docker does not.
# Assert on the stable runtime contract instead of passwd database implementation details.
check "Red Hat Hardened Images runtime uid is 65532" bash -lc 'test "$(id -u)" = "65532"'
check "Red Hat Hardened Images runtime home is /tmp" bash -lc 'test "${HOME}" = "/tmp"'
check "Red Hat Hardened Images runtime home dir not under /home" bash -lc 'case "${HOME}" in /home/*) exit 1 ;; *) exit 0 ;; esac'
check "hello" hello --version
check "brew removed" bash -lc '! command -v brew >/dev/null 2>&1'
check "homebrew checkout removed" bash -lc '! test -e /home/linuxbrew/.linuxbrew/Homebrew'

reportResults

#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "Red Hat Hardened Images runtime uid 65532 exists" getent passwd 65532
check "Red Hat Hardened Images runtime user home is /tmp" bash -lc 'test "$(getent passwd 65532 | cut -d: -f6)" = "/tmp"'
check "Red Hat Hardened Images runtime user home dir not under /home" bash -lc 'runtime_user="$(getent passwd 65532 | cut -d: -f1)"; ! test -e "/home/${runtime_user}"'
check "hello" hello --version
check "brew removed" bash -lc '! command -v brew >/dev/null 2>&1'
check "homebrew checkout removed" bash -lc '! test -e /home/linuxbrew/.linuxbrew/Homebrew'

reportResults

#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "hello" hello --version
check "ubuntu user exists" bash -lc 'id -u ubuntu >/dev/null 2>&1'
check "homebrew parent owned by ubuntu" bash -lc 'test "$(stat -c %U /home/linuxbrew)" = "ubuntu"'
check "brew removed" bash -lc '! command -v brew >/dev/null 2>&1'
check "homebrew checkout removed" bash -lc '! test -e /home/linuxbrew/.linuxbrew/Homebrew'

reportResults

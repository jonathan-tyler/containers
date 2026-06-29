#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "hello" hello --version
check "nonroot user exists" bash -lc 'id -u nonroot >/dev/null 2>&1'
check "homebrew parent owned by nonroot" bash -lc 'test "$(stat -c %U /home/linuxbrew)" = "nonroot"'
check "brew removed" bash -lc '! command -v brew >/dev/null 2>&1'
check "homebrew checkout removed" bash -lc '! test -e /home/linuxbrew/.linuxbrew/Homebrew'

reportResults

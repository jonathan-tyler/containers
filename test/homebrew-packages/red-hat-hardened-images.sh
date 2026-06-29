#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "runtime user is nonroot" bash -lc 'test "$(id -un)" = "nonroot"'
check "runtime uid is 1000" bash -lc 'test "$(id -u)" = "1000"'
check "nonroot home directory exists" bash -lc 'test -d /home/nonroot'
check "hello" hello --version
check "brew removed" bash -lc '! command -v brew >/dev/null 2>&1'
check "homebrew checkout removed" bash -lc '! test -e /home/linuxbrew/.linuxbrew/Homebrew'

reportResults

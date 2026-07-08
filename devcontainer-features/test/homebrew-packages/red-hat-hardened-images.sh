#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "hello" hello --version
check "gcc available" gcc --version
check "g++ available" g++ --version
check "make available" make --version
check "patch available" patch --version
check "brew removed" bash -lc '! command -v brew >/dev/null 2>&1'
check "homebrew checkout removed" bash -lc '! test -e /home/linuxbrew/.linuxbrew/Homebrew'

reportResults

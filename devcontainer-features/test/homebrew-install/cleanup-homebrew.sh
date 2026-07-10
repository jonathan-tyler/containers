#!/bin/bash

set -e

. ./dev-container-features-test-lib

check "gcc available" gcc --version
check "g++ available" g++ --version
check "make available" make --version
check "patch available" patch --version
check "brew removed" sh -lc '! command -v brew >/dev/null 2>&1'
check "homebrew checkout removed" sh -lc '! test -e /home/linuxbrew/.linuxbrew/Homebrew'
check "default cache removed" sh -lc '! test -e /tmp/homebrew-cache'

reportResults

#!/bin/sh

set -e

. dev-container-features-test-lib

check "hello" hello --version
check "gcc available" gcc --version
check "g++ available" g++ --version
check "make available" make --version
check "patch available" patch --version
check "nonroot user exists" sh -lc 'id -u nonroot >/dev/null 2>&1'
check "homebrew parent owned by nonroot" sh -lc 'test "$(stat -c %U /home/linuxbrew)" = "nonroot"'
check "brew removed" sh -lc '! command -v brew >/dev/null 2>&1'
check "homebrew checkout removed" sh -lc '! test -e /home/linuxbrew/.linuxbrew/Homebrew'

reportResults

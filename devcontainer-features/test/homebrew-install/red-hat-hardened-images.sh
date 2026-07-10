#!/bin/bash

set -e

. ./dev-container-features-test-lib

check "brew available" brew --version
check "gcc available" gcc --version
check "g++ available" g++ --version
check "make available" make --version
check "patch available" patch --version
check "brew symlink available" sh -lc 'test -x /usr/local/bin/brew'
check "homebrew checkout kept" sh -lc 'test -e /home/linuxbrew/.linuxbrew/Homebrew'

reportResults

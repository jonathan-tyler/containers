#!/bin/sh

set -e

. dev-container-features-test-lib

check "hello" hello --version
check "custom cache directory kept" sh -lc 'set -- /var/cache/homebrew/*; test "$1" != "/var/cache/homebrew/*"'
check "default cache not used" sh -lc '! test -e /tmp/homebrew-cache'
check "brew removed" sh -lc '! command -v brew >/dev/null 2>&1'
check "homebrew checkout removed" sh -lc '! test -e /home/linuxbrew/.linuxbrew/Homebrew'

reportResults

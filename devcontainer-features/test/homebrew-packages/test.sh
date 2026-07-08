#!/bin/sh

set -e

. dev-container-features-test-lib

check "brew removed" sh -lc '! command -v brew >/dev/null 2>&1'
check "homebrew checkout removed" sh -lc '! test -e /home/linuxbrew/.linuxbrew/Homebrew'

reportResults

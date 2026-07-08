#!/bin/sh

set -e

. dev-container-features-test-lib

check "hello" hello --version
check "existing brew bootstrap not attempted" sh -lc '! test -e /tmp/homebrew-bootstrap-attempted'
check "brew removed" sh -lc '! command -v brew >/dev/null 2>&1'
check "existing brew checkout removed" sh -lc '! test -e /opt/existing-brew-root/Homebrew'

reportResults

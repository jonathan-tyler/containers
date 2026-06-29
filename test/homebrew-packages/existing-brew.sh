#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "hello" hello --version
check "existing brew bootstrap not attempted" bash -lc '! test -e /tmp/homebrew-bootstrap-attempted'
check "brew removed" bash -lc '! command -v brew >/dev/null 2>&1'
check "existing brew checkout removed" bash -lc '! test -e /opt/existing-brew-root/Homebrew'

reportResults

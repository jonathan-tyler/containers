#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "opencode binary" bash -lc 'opencode --help >/dev/null'

reportResults

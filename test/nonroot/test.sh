#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "nonroot passwd entry exists" bash -lc 'getent passwd nonroot >/dev/null'
check "nonroot home exists" bash -lc 'test -d /home/nonroot'

reportResults

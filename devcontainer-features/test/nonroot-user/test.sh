#!/bin/bash

set -e

. ./dev-container-features-test-lib

check "nonroot passwd entry exists" sh -lc 'getent passwd nonroot >/dev/null'
check "nonroot home exists" sh -lc 'test -d /home/nonroot'

reportResults

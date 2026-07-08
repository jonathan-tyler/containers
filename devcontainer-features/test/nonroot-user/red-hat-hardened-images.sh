#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "nonroot passwd entry exists" bash -lc 'getent passwd nonroot >/dev/null'
check "nonroot uid is 1000" bash -lc 'test "$(id -u nonroot)" = "1000"'
check "nonroot gid is 1000" bash -lc 'test "$(id -g nonroot)" = "1000"'
check "nonroot home exists" bash -lc 'test -d /home/nonroot'

reportResults

#!/bin/bash

set -e

. ./dev-container-features-test-lib

check "nonroot passwd entry exists" sh -lc 'getent passwd nonroot >/dev/null'
check "nonroot uid is 1000" sh -lc 'test "$(id -u nonroot)" = "1000"'
check "nonroot gid is 1000" sh -lc 'test "$(id -g nonroot)" = "1000"'
check "nonroot home exists" sh -lc 'test -d /home/nonroot'

reportResults

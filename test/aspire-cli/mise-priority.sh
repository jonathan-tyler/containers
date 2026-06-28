#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "aspire" aspire --version
check "mise selected" bash -lc 'test "$(cat /tmp/aspire-installer)" = "mise"'

reportResults

#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "aspire" aspire --version
check "nuget selected" bash -lc 'test "$(cat /tmp/aspire-installer)" = "nuget"'

reportResults

#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "aspire" bash -lc 'test "$(aspire --version)" = "0.0.0-preinstalled"'
check "existing aspire kept" bash -lc 'test "$(readlink -f "$(command -v aspire)")" = "/usr/local/bin/aspire"'
check "npm install skipped" bash -lc '! test -d "$(npm root -g)/@microsoft/aspire-cli"'

reportResults

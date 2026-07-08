#!/bin/sh

set -e

. dev-container-features-test-lib

check "aspire" sh -lc 'test "$(aspire --version)" = "0.0.0-preinstalled"'
check "existing aspire kept" sh -lc 'test "$(readlink -f "$(command -v aspire)")" = "/usr/local/bin/aspire"'
check "npm install skipped" sh -lc '! test -d "$(npm root -g)/@microsoft/aspire-cli"'

reportResults

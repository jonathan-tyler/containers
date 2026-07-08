#!/bin/sh

set -e

. dev-container-features-test-lib

check "aspire" aspire --version
check "npm package installed" sh -lc 'test -d "$(npm root -g)/@microsoft/aspire-cli"'
check "npm selected" sh -lc 'test "$(readlink -f "$(command -v aspire)")" = "$(npm prefix -g)/lib/node_modules/@microsoft/aspire-cli/bin/aspire.js"'

reportResults

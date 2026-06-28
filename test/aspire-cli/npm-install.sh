#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "aspire" aspire --version
check "npm package installed" bash -lc 'test -d "$(npm root -g)/@microsoft/aspire-cli"'

reportResults

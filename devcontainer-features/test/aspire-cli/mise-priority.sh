#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "aspire" aspire --version
check "mise selected" bash -lc 'test "$(readlink -f "$(command -v aspire)")" = "/tmp/mock-mise/installs/aspire/1.0.0/bin/aspire"'

reportResults

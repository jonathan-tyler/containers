#!/bin/sh

set -e

. dev-container-features-test-lib

check "aspire" aspire --version
check "mise selected" sh -lc 'test "$(readlink -f "$(command -v aspire)")" = "/tmp/mock-mise/installs/aspire/1.0.0/bin/aspire"'

reportResults

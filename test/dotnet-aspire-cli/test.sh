#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "aspire cli" bash -lc 'aspire --help >/dev/null'

reportResults

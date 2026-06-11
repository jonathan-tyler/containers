#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "git" git --version
check "jq" jq --version
check "ripgrep" rg --version
check "tar" tar --version

reportResults

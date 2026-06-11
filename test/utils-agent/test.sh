#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "yq" yq --version
check "shellcheck" shellcheck --version
check "shfmt" shfmt --version
check "yamllint" yamllint --version

reportResults

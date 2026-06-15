#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "runtime user exists" getent passwd devcontainer
check "runtime user uid" test "$(id -u devcontainer)" = "65532"

reportResults

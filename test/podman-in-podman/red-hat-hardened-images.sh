#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "Red Hat Hardened Images runtime user exists" getent passwd devcontainer
check "Red Hat Hardened Images runtime user uid" test "$(id -u devcontainer)" = "65532"

reportResults

#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "podman" podman --version
check "init script executable" test -x /usr/local/share/podman-outside-of-podman-init.sh
check "init script exports CONTAINER_HOST" grep -q CONTAINER_HOST /usr/local/share/podman-outside-of-podman-init.sh

reportResults

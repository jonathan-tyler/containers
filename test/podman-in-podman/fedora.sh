#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "podman installed on fedora fallback path" podman --version
check "init script executable on fedora fallback path" test -x /usr/local/share/podman-in-podman-init.sh
check "fedora fallback path does not add hummingbird repo file" bash -lc '! test -e /etc/yum.repos.d/hummingbird.repo'

reportResults

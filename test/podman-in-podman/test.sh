#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "podman" podman --version
check "podman user exists" getent passwd podman
check "subuid entry" grep -q '^podman:' /etc/subuid
check "subgid entry" grep -q '^podman:' /etc/subgid
check "containers config" test -f /etc/containers/containers.conf
check "storage config" test -f /etc/containers/storage.conf
check "init script executable" test -x /usr/local/share/podman-in-podman-init.sh

reportResults

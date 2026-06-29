#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "existing podman version preserved" bash -lc 'podman --version | grep -q "existing-podman 1.0"'
check "existing podman path preserved" bash -lc 'test "$(command -v podman)" = "/opt/existing-podman-root/bin/podman"'
check "podman package install not attempted" bash -lc '! test -e /tmp/podman-package-install-attempted'
check "fedora repo file not written for reused podman" bash -lc '! test -e /etc/yum.repos.d/fedora.repo'

reportResults

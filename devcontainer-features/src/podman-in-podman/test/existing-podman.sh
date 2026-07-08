#!/bin/sh

set -e

. dev-container-features-test-lib

check "existing podman version preserved" sh -lc 'podman --version | grep -q "existing-podman 1.0"'
check "existing podman path preserved" sh -lc 'test "$(command -v podman)" = "/opt/existing-podman-root/bin/podman"'
check "podman package install not attempted" sh -lc '! test -e /tmp/podman-package-install-attempted'
check "fedora repo file not written for reused podman" sh -lc '! test -e /etc/yum.repos.d/fedora.repo'

reportResults

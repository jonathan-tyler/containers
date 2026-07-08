#!/bin/sh

set -e

. dev-container-features-test-lib

check "podman" podman --version
check "podman user exists" getent passwd podman
check "podman subuid entry" grep -q '^podman:' /etc/subuid
check "podman subgid entry" grep -q '^podman:' /etc/subgid
check "containers config" test -f /etc/containers/containers.conf
check "storage config" test -f /etc/containers/storage.conf
check "storage config uses fuse-overlayfs on PATH" sh -lc 'grep -q "^mount_program = \"$(command -v fuse-overlayfs)\"$" /etc/containers/storage.conf'
check "temporary Fedora repo file removed" sh -lc '! test -e /etc/yum.repos.d/podman-in-podman-fedora.repo'
check "init script executable" test -x /usr/local/share/podman-in-podman-init.sh

reportResults

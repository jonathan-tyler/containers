#!/bin/sh

set -e

. dev-container-features-test-lib

check "podman socket sentinel preserved" sh -lc 'test -f /run/podman/podman.sock && ! test -S /run/podman/podman.sock'
check "no host podman socket mounted at /var/run" sh -lc '! test -S /var/run/podman/podman.sock'
check "no host docker socket mounted" sh -lc '! test -S /var/run/docker.sock'

reportResults

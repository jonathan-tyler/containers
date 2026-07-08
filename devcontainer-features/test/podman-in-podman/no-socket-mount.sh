#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "podman socket sentinel preserved" bash -lc 'test -f /run/podman/podman.sock && ! test -S /run/podman/podman.sock'
check "no host podman socket mounted at /var/run" bash -lc '! test -S /var/run/podman/podman.sock'
check "no host docker socket mounted" bash -lc '! test -S /var/run/docker.sock'

reportResults

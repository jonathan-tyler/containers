#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

runtime_uid="$(id -u)"
check "feature does not leave temporary Fedora repo files" bash -lc '! test -e /etc/yum.repos.d/podman-in-podman-fedora.repo && ! test -e /etc/yum.repos.d/fedora.repo'
check "init script sets XDG runtime dir for runtime uid" bash -lc "unset XDG_RUNTIME_DIR; test \"\$(/usr/local/share/podman-in-podman-init.sh sh -lc 'printf %s \"\${XDG_RUNTIME_DIR}\"')\" = \"/tmp/podman-run-${runtime_uid}\""
check "init script creates private XDG runtime dir" bash -lc "unset XDG_RUNTIME_DIR; /usr/local/share/podman-in-podman-init.sh true; test -d \"/tmp/podman-run-${runtime_uid}\" && test \"\$(stat -c %a \"/tmp/podman-run-${runtime_uid}\")\" = \"700\""
check "runtime subuid entry exists" bash -lc 'grep -q "^nonroot:" /etc/subuid'
check "runtime subgid entry exists" bash -lc 'grep -q "^nonroot:" /etc/subgid'

reportResults

#!/bin/bash

set -e

. ./dev-container-features-test-lib

runtime_uid="$(id -u)"
expected_home="$(grep -m1 "^[^:]*:[^:]*:${runtime_uid}:" /etc/passwd 2>/dev/null | cut -d: -f6 || true)"
expected_runtime_dir="${expected_home}/.podman-run-${runtime_uid}"
check "feature does not leave temporary Fedora repo files" sh -lc '! test -e /etc/yum.repos.d/podman-in-podman-fedora.repo && ! test -e /etc/yum.repos.d/fedora.repo'
check "init script sets XDG runtime dir for runtime uid" sh -lc "unset XDG_RUNTIME_DIR; test \"\$(/usr/local/share/podman-in-podman-init.sh sh -lc 'printf %s \"\${XDG_RUNTIME_DIR}\"')\" = \"${expected_runtime_dir}\""
check "init script creates private XDG runtime dir" sh -lc "unset XDG_RUNTIME_DIR; /usr/local/share/podman-in-podman-init.sh true; test -d \"${expected_runtime_dir}\" && test \"\$(stat -c %a \"${expected_runtime_dir}\")\" = \"700\""
check "runtime subuid entry exists" sh -lc 'grep -q "^nonroot:" /etc/subuid'
check "runtime subgid entry exists" sh -lc 'grep -q "^nonroot:" /etc/subgid'

reportResults

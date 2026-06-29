#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "Red Hat Hardened Images runtime uid is 65532" bash -lc 'test "$(id -u)" = "65532"'
check "Red Hat Hardened Images runtime home is /tmp" bash -lc 'test "${HOME}" = "/tmp"'
check "Red Hat Hardened Images runtime home is not under /home" bash -lc 'case "${HOME}" in /home/*) exit 1 ;; *) exit 0 ;; esac'
check "feature does not leave temporary Fedora repo files" bash -lc '! test -e /etc/yum.repos.d/podman-in-podman-fedora.repo && ! test -e /etc/yum.repos.d/fedora.repo'
check "init script sets XDG runtime dir for uid 65532" bash -lc 'unset XDG_RUNTIME_DIR; test "$(/usr/local/share/podman-in-podman-init.sh sh -lc '"'"'printf %s "${XDG_RUNTIME_DIR}"'"'"')" = "/tmp/podman-run-65532"'
check "init script creates private XDG runtime dir" bash -lc 'unset XDG_RUNTIME_DIR; /usr/local/share/podman-in-podman-init.sh true; test -d /tmp/podman-run-65532 && test "$(stat -c %a /tmp/podman-run-65532)" = "700"'
check "runtime subuid entry exists" bash -lc 'runtime_user="$(grep -m1 "^[^:]*:[^:]*:65532:" /etc/passwd | cut -d: -f1)"; if [ -n "${runtime_user}" ]; then grep -qE "^(${runtime_user}|65532):" /etc/subuid; else grep -q "^65532:" /etc/subuid; fi'
check "runtime subgid entry exists" bash -lc 'runtime_user="$(grep -m1 "^[^:]*:[^:]*:65532:" /etc/passwd | cut -d: -f1)"; if [ -n "${runtime_user}" ]; then grep -qE "^(${runtime_user}|65532):" /etc/subgid; else grep -q "^65532:" /etc/subgid; fi'

reportResults

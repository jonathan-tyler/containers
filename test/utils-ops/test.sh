#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "curl" curl --version
check "wget" wget --version
check "iproute" ip -V
check "ssh" ssh -V
check "rsync" rsync --version
check "strace" strace -V

reportResults

#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "hello" hello --version
check "custom cache directory kept" bash -lc 'shopt -s nullglob dotglob; cache_entries=(/var/cache/homebrew/*); test "${#cache_entries[@]}" -gt 0'
check "default cache not used" bash -lc '! test -e /tmp/homebrew-cache'
check "brew removed" bash -lc '! command -v brew >/dev/null 2>&1'
check "homebrew checkout removed" bash -lc '! test -e /home/linuxbrew/.linuxbrew/Homebrew'

reportResults

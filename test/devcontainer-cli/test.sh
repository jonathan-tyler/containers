#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "podman" podman --version
check "devcontainer cli" devcontainer --version

reportResults

#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "aspire" aspire --version
check "nuget selected" bash -lc 'case "$(readlink -f "$(command -v aspire)")" in /usr/local/share/aspire-cli/dotnet-tools/*) exit 0 ;; *) exit 1 ;; esac'

reportResults

#!/usr/bin/env bash

set -euo pipefail

FEATURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./lib.sh
source "${FEATURE_DIR}/lib.sh"

requireRoot

installer="$(selectInstaller)"
installAspireCli "${installer}"
verifyAspireCli

echo "Installed Aspire CLI with ${installer}."

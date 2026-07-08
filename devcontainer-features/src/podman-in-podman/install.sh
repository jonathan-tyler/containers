#!/usr/bin/env bash

set -euo pipefail

FEATURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./lib.sh
source "${FEATURE_DIR}/lib.sh"
# shellcheck source=./lib-fedora-rhel.sh
source "${FEATURE_DIR}/lib-fedora-rhel.sh"

requireRoot

resolved_user="$(resolveRuntimeUser)"
installPodmanPackagesIfNeeded
fuse_overlayfs_path="$(command -v fuse-overlayfs)"

ensurePodmanUser
writePodmanConfigs "${fuse_overlayfs_path}"
writeInitScript
configureRootlessUsers "${resolved_user}"
cleanupFedoraRhelPackages

echo "Done!"

#!/usr/bin/env bash

set -euo pipefail

jq -e '
  .id == "fedora-dnf-repo"
  and .name == "Fedora DNF Repo"
  and (.description | test("dnf-based Fedora and RHEL-family images"))
' devcontainer-features/fedora-dnf-repo/devcontainer-feature.json >/dev/null

grep -q 'FEDORA_REPO_ID="fedora"' devcontainer-features/fedora-dnf-repo/install.sh
grep -q 'should_write_fedora_repo' devcontainer-features/fedora-dnf-repo/install.sh

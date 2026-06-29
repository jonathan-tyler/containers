#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

packages=(
    bat
    difftastic
    eza
    fd
    fzf
    git-delta
    jq
    lazygit
    neovim
    opencode
    sesh
    starship
    tree-sitter-cli
    tmux
    yazi
    zoxide
    zsh
    zsh-vi-mode
    zsh-autosuggestions
)

for package in "${packages[@]}"; do
    check "${package} installed" bash -lc "test -d /home/linuxbrew/.linuxbrew/Cellar/${package}"
done

check "brew removed" bash -lc '! command -v brew >/dev/null 2>&1'
check "homebrew checkout removed" bash -lc '! test -e /home/linuxbrew/.linuxbrew/Homebrew'

reportResults

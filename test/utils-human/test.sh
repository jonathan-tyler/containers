#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "zsh" zsh --version
check "tmux" tmux -V
check "starship" starship --version
check "neovim" nvim --version
check "eza" eza --version
check "yazi" yazi --version
check "zoxide" zoxide --version
check "fzf" fzf --version
check "delta" delta --version
check "difftastic" difft --version
check "lazygit" lazygit --version
check "zsh autosuggestions plugin" test -d /root/.local/share/zsh/plugins/zsh-autosuggestions
check "zsh vi mode plugin" test -d /root/.local/share/zsh/plugins/zsh-vi-mode

reportResults

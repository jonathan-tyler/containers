# Human Utilities (`utils-human`)

Install interactive shell and terminal utilities on top of the shared `utils-core` baseline without applying user config.

## Example Usage

```json
"features": {
  "./devcontainer-features/utils-human": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| INSTALL_ZSH | Install zsh? | boolean | true |
| SET_ZSH_AS_DEFAULT_SHELL | Set zsh as the default shell for the configured user? | boolean | false |
| INSTALL_ZSH_AUTOSUGGESTIONS | Install the zsh-autosuggestions plugin archive into the target user's data directory? | boolean | true |
| INSTALL_ZSH_VI_MODE | Install the zsh-vi-mode plugin archive into the target user's data directory? | boolean | true |
| INSTALL_STARSHIP | Install starship? | boolean | true |
| INSTALL_TMUX | Install tmux? | boolean | true |
| INSTALL_TREE | Install tree? | boolean | false |
| INSTALL_MAN_DB | Install man-db? | boolean | false |
| INSTALL_MAN_PAGES | Install man-pages? | boolean | false |
| INSTALL_BAT | Install bat? | boolean | false |
| INSTALL_BTOP | Install btop? | boolean | false |
| INSTALL_NEOVIM | Install Neovim? | boolean | true |
| INSTALL_EZA | Install eza? | boolean | true |
| INSTALL_YAZI | Install yazi and ya? | boolean | true |
| INSTALL_ZOXIDE | Install zoxide? | boolean | true |
| INSTALL_SESH | Install sesh? | boolean | true |
| INSTALL_FZF | Install fzf? | boolean | true |
| INSTALL_DELTA | Install delta? | boolean | true |
| INSTALL_DIFFTASTIC | Install difftastic? | boolean | true |
| INSTALL_LAZYGIT | Install lazygit? | boolean | true |
| USERNAME | User whose home directory should receive plugin infrastructure. | string | automatic |

## Notes

- This feature depends on `utils-core` for the shared local workspace baseline.
- This feature follows the tool list and plugin paths from `/home/him/setup/install-apps`, but leaves shell, editor, and tool configuration out of scope.
- The zsh plugins are installed into `${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins` for the configured user so later dotfiles can source them without re-downloading.
- `zsh-autosuggestions` and `zsh-vi-mode` are installed as plugin infrastructure only. No `.zshrc`, tmux config, Neovim config, yazi config, or lazygit config is installed.
- `tree`, `man-db`, `man-pages`, `bat`, and `btop` are optional human-mode additions and default to disabled.
- The feature uses `dnf` plus upstream release archives so it does not depend on every requested tool being packaged in the base image repositories.

## OS Support

This feature currently targets Fedora and RHEL-family images with `dnf`.

## Reference

- `/home/him/setup/install-apps`
- `/home/him/.local/share/chezmoi/.chezmoiexternal.toml.tmpl`
- `https://github.com/devcontainers/features/tree/main/src/common-utils`

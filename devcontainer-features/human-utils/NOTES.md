## Notes

- This feature depends on `core-utils` for the shared local workspace baseline.
- This feature installs tools and lightweight plugin payloads, but intentionally does not write user config files.
- The zsh plugin paths match the chezmoi-managed shell setup under `${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins`.
- The optional `tree`, `man-db`, `man-pages`, `bat`, and `btop` packages are intended for interactive human workflows rather than the shared baseline, so they default to off.
- The plugin versions currently mirror the archives pinned in `/home/him/.local/share/chezmoi/.chezmoiexternal.toml.tmpl`.

## Limitations

- This feature currently targets Fedora and RHEL-family images with `dnf`.
- Binary archive URLs are pinned in the install script, so refreshing tool versions is a source change rather than a runtime discovery step.

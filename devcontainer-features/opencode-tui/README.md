# OpenCode TUI (`opencode-tui`)

Install the OpenCode terminal UI without applying user config.

## Example Usage

```json
"features": {
  "ghcr.io/jonathan-tyler/containers/opencode-tui:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| VERSION | OpenCode version to install. Use `latest` for the current release. | string | latest |

## Notes

- Running `opencode` without arguments starts the terminal UI in the current working directory.
- This feature installs the OpenCode binary only. It does not install provider credentials, `opencode.json`, `tui.json`, themes, or other personal config.

## OS Support

This feature currently targets Fedora and RHEL-family images with `dnf`.

## Reference

- https://opencode.ai/docs/
- https://opencode.ai/docs/tui/

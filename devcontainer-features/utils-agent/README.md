# Agent Utilities (`utils-agent`)

Install local analysis and formatting utilities for AI-agent workflows.

## Example Usage

```json
"features": {
  "ghcr.io/jonathan-tyler/containers/utils-human:0": {},
  "ghcr.io/jonathan-tyler/containers/utils-agent:0": {}
}
```

## Included Tools

- `yq`
- `shellcheck`
- `shfmt`
- `yamllint`
- `patchutils`
- `diffstat`

## Notes

- This feature depends on `utils-core` for the shared local workspace baseline.
- The package set is aimed at local analysis, linting, and formatting rather than shell comfort or network operations.

## OS Support

This feature currently targets Fedora and RHEL-family images with `dnf`.

## Reference

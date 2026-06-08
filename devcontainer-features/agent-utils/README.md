# Agent Utilities (`agent-utils`)

Install local analysis and formatting utilities for AI-agent workflows.

## Example Usage

```json
"features": {
  "./devcontainer-features/human-utils": {},
  "./devcontainer-features/agent-utils": {}
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

- This feature depends on `core-utils` for the shared local workspace baseline.
- The package set is aimed at local analysis, linting, and formatting rather than shell comfort or network operations.

## OS Support

This feature currently targets Fedora and RHEL-family images with `dnf`.

## Reference

- https://github.com/devcontainers/features/tree/main/src/common-utils

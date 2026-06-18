# Core Utilities (`utils-core`)

Install shared local workspace utilities for both human and agent workflows.

## Example Usage

```json
"features": {
  "ghcr.io/jonathan-tyler/containers/utils-core:0": {}
}
```

## Included Tools

- `git`
- `jq`
- `ripgrep`
- `findutils`, `grep`, `sed`, `gawk`
- `diffutils`, `patch`
- `file`, `which`
- `tar`, `gzip`, `xz`, `unzip`, `zip`
- `less`
- `procps-ng`
- `fd` when a suitable package is available for the base image
- Fedora is added as a lower-priority fallback repo only when Hummingbird is the sole enabled repo.

## Notes

- This feature is the shared prerequisite for `utils-human`, `utils-agent`, and `utils-ops`.
- The package set stays focused on local workspace inspection and basic file manipulation rather than network or admin tooling.

## OS Support

This feature currently targets Fedora and RHEL-family images with `dnf`.

## Reference

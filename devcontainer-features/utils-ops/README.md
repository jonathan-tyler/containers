# Ops Utilities (`utils-ops`)

Install network, remote access, and low-level diagnostic utilities for operational workflows.

## Example Usage

```json
"features": {
  "./devcontainer-features/utils-human": {},
  "./devcontainer-features/utils-ops": {}
}
```

## Included Tools

- `curl`
- `wget`
- `openssh-clients`
- `rsync`
- `lsof`
- `iproute`
- `net-tools`
- `bind-utils`
- `nmap-ncat`
- `socat`
- `strace`
- `psmisc`

## Notes

- This feature depends on `utils-core` for the shared local workspace baseline.
- The package set is intentionally more operational and higher trust than `utils-human` or `utils-agent`.

## OS Support

This feature currently targets Fedora and RHEL-family images with `dnf`.

## Reference

- https://github.com/devcontainers/features/tree/main/src/common-utils

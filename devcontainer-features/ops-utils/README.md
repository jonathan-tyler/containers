# Ops Utilities (`ops-utils`)

Install network, remote access, and low-level diagnostic utilities for operational workflows.

## Example Usage

```json
"features": {
  "./devcontainer-features/human-utils": {},
  "./devcontainer-features/ops-utils": {}
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

- This feature depends on `core-utils` for the shared local workspace baseline.
- The package set is intentionally more operational and higher trust than `human-utils` or `agent-utils`.

## OS Support

This feature currently targets Fedora and RHEL-family images with `dnf`.

## Reference

- https://github.com/devcontainers/features/tree/main/src/common-utils

## Notes

- The feature prefers the least-surprising nested setup: rootless outer container support via `label=disable`, `/dev/fuse`, `fuse-overlayfs` storage, and isolated storage volumes.
- When resolving the runtime user, it checks UID `65532` first, then common non-root usernames like `vscode`, `node`, and `codespace`, and falls back to root if none exist.
- On Red Hat hardened images, the installer writes Fedora repo files before installing Podman dependencies.
- It writes `/etc/containers/containers.conf` and `/etc/containers/storage.conf` so the installed Podman uses settings that are friendlier to containerized execution.
- A `podman` user is created with split subuid and subgid ranges that preserve the caller UID while still covering inner image UIDs like `65532`, and the detected non-root devcontainer user gets the same treatment when needed.

## Limitations

- This feature currently targets Fedora and RHEL-family images with `dnf`.
- If your consuming `devcontainer.json` does not pass `/dev/fuse` and `/dev/net/tun`, nested Podman may not be able to launch rootless containers with the recommended storage and network paths.

Use these `runArgs` in the consuming `devcontainer.json`:

```json
"runArgs": [
  "--device=/dev/fuse",
  "--device=/dev/net/tun",
  "--security-opt=seccomp=unconfined"
]
```

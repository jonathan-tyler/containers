## Notes

- The feature prefers the least-surprising nested setup: rootless outer container support via `label=disable`, `/dev/fuse`, `fuse-overlayfs` storage, and isolated storage volumes.
- It writes `/etc/containers/containers.conf` and `/etc/containers/storage.conf` so the installed Podman uses settings that are friendlier to containerized execution.
- A `podman` user is created with subuid and subgid ranges, and the detected non-root devcontainer user also gets a range when possible.

## Limitations

- This feature currently targets Fedora and RHEL-family images with `dnf`.
- If your consuming `devcontainer.json` does not pass `/dev/fuse`, nested Podman may not be able to use the recommended `fuse-overlayfs` storage path.

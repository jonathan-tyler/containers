# Podman (Podman-in-Podman) (`podman-in-podman`)

Run Podman inside the dev container with isolated storage volumes and container-friendly Podman defaults.

## Example Usage

```json
"features": {
  "./devcontainer-features/podman-in-podman": {}
}
```

## Notes

- This feature follows the same general pattern as `docker-in-docker`, but uses Podman and the nested-container guidance from Red Hat's [How to use Podman inside of a container](https://www.redhat.com/en/blog/podman-inside-container).
- For a rootless outer dev container, pass `--security-opt label=disable` and `--device /dev/fuse` in the consuming `devcontainer.json`, matching the article's `podman run --security-opt label=disable --user podman --device /dev/fuse quay.io/podman/stable podman run alpine echo hello` example.
- The feature prefers an existing passwd entry for UID `65532`, then common non-root usernames, then root. That lets hardened Red Hat images use their built-in numeric identity when present.
- Rootful storage is persisted in `/var/lib/containers`, and a separate volume is mounted for the bundled `podman` user's rootless storage.
- The feature installs `fuse-overlayfs`, `uidmap`, and `slirp4netns`, and switches Podman's engine settings to `cgroupfs` with a container-friendly overlay configuration.

## OS Support

This feature currently targets Fedora and RHEL-family images with `dnf`.

## Reference

- https://www.redhat.com/en/blog/podman-inside-container

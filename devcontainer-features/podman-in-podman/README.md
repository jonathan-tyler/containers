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
- On Red Hat hardened images, the installer adds Fedora package repositories so the Podman stack can be installed there.
- For a rootless outer dev container, pass `--security-opt label=disable`, `--security-opt seccomp=unconfined`, `--device /dev/fuse`, and `--device /dev/net/tun` in the consuming `devcontainer.json`.
- The feature prefers an existing passwd entry for UID `65532`, then common non-root usernames, then root. That lets hardened Red Hat images use their built-in numeric identity when present.
- Rootful storage is persisted in `/var/lib/containers`, and a separate volume is mounted for the bundled `podman` user's rootless storage.
- The feature installs `fuse-overlayfs`, `uidmap`, and `slirp4netns`, switches Podman's engine settings to `cgroupfs` with a container-friendly overlay configuration, and writes split subuid/subgid ranges so nested rootless Podman can still run images whose default user is `65532`.

## OS Support

This feature currently targets Fedora and RHEL-family images with `dnf`.

## Reference

- https://www.redhat.com/en/blog/podman-inside-container

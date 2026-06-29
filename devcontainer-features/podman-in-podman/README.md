# Podman-in-Podman (`podman-in-podman`)

Run Podman inside the dev container with isolated storage volumes and container-friendly Podman defaults.

## Example Usage

```json
"features": {
  "ghcr.io/jonathan-tyler/containers/podman-in-podman:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| username | User that should receive rootless subuid and subgid ranges when the image already defines a non-root runtime user. | string | automatic |

## Notes

- The feature uses isolated storage volumes for `/var/lib/containers` and `/home/podman/.local/share/containers`; it does not mount a host Podman socket into the container.
- If `podman` is already available on `PATH`, the feature reuses that installation instead of installing another copy.
- On Red Hat hardened images, the runtime user is commonly UID `65532` with `HOME=/tmp` and no `/home/<user>` directory. The image may not ship a stable passwd entry for that UID, and Podman may synthesize one at runtime, so the feature targets the stable runtime contract instead of assuming a specific passwd record.
- If the image already enables the Red Hat `public-hummingbird-x86_64-rpms` repo, the installer tries that repo first. If hummingbird alone cannot satisfy the full Podman dependency graph and no other `dnf` repos are already enabled, the installer temporarily enables Fedora repos just long enough to install the missing stack, then removes that temporary repo file from the final image. When hummingbird is absent, it uses whatever `dnf` repositories the image already has configured.
- For a rootless outer dev container, pass `--security-opt label=disable`, `--security-opt seccomp=unconfined`, `--device /dev/fuse`, and `--device /dev/net/tun` in the consuming `devcontainer.json`.

## OS Support

This feature targets images with `dnf` available when package installation is required. Images that already provide a working Podman stack can be reused without reinstalling Podman.

## Reference

- https://www.redhat.com/en/blog/podman-inside-container

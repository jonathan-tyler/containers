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
- On Red Hat hardened images, the feature supports the numeric UID `65532` runtime user with `HOME=/tmp` and sets a private `XDG_RUNTIME_DIR` automatically when needed.
- On RHEL-family images that do not already include Podman, the installer adds Fedora package repositories so the Podman stack can be installed there.
- For a rootless outer dev container, pass `--security-opt label=disable`, `--security-opt seccomp=unconfined`, `--device /dev/fuse`, and `--device /dev/net/tun` in the consuming `devcontainer.json`.

## OS Support

This feature targets Fedora and RHEL-family images when package installation is required. Images that already provide a working Podman stack can be reused without reinstalling Podman.

## Reference

- https://www.redhat.com/en/blog/podman-inside-container

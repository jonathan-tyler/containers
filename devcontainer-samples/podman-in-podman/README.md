# podman-in-podman

Single-container devcontainer sample for the `podman-in-podman` feature on `registry.access.redhat.com/hi/core-runtime:latest-builder`.

Open this folder in Dev Containers. The sample applies the published `nonroot-user` and `podman-in-podman` features and includes the extra container runtime arguments needed for nested Podman to work.

## Files

- `.devcontainer/devcontainer.json`: devcontainer entry point with the feature and required run arguments.

## Notes

- Base image: `registry.access.redhat.com/hi/core-runtime:latest-builder`
- Feature: `ghcr.io/jonathan-tyler/containers/podman-in-podman:0`
- Runtime user: named user `nonroot` created by `ghcr.io/jonathan-tyler/containers/nonroot-user:0`
- Required run arguments in this sample:
  - `--device=/dev/fuse`
  - `--device=/dev/net/tun`
  - `--security-opt=seccomp=unconfined`
- The feature itself supplies `label=disable` and the isolated Podman storage volume mounts.

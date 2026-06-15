# Podman (Podman-outside-of-Podman) (`podman-outside-of-podman`)

Reuse the host Podman socket from a dev container by installing the Podman CLI and exporting the mounted socket as `CONTAINER_HOST`.

## Example Usage

```json
"features": {
  "./devcontainer-features/podman-outside-of-podman": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| socketPath | Path where the host Podman socket is mounted inside the container. Override the mount in `devcontainer.json` if your host socket lives elsewhere. | string | /run/user-host/podman/podman.sock |

## Notes

- This mirrors the host-socket pattern from `docker-outside-of-docker`, but points the Podman CLI at a mounted host Podman socket instead of starting a nested engine.
- On Red Hat hardened images, the installer adds Fedora package repositories so the Podman CLI stack can be installed there.
- The default mount assumes a rootless host Podman socket at `${localEnv:XDG_RUNTIME_DIR}/podman/podman.sock`.
- The feature exports both `CONTAINER_HOST` and `DOCKER_HOST` so Podman-aware tooling and Docker-API-compatible tooling can use the mounted host socket.

## Security

Leaking the host Podman socket into a dev container gives processes inside that container broad control over the host container engine. Treat this as a convenience tradeoff, not a hard isolation boundary.

## OS Support

This feature currently targets Fedora and RHEL-family images with `dnf`.

## Reference

- https://www.redhat.com/en/blog/podman-inside-container

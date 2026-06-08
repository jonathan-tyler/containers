## Notes

- The default mount targets the common rootless Podman socket location from the host: `${localEnv:XDG_RUNTIME_DIR}/podman/podman.sock`.
- If your host uses a different socket, override the mount in `devcontainer.json` and set the feature's `socketPath` option to the same in-container path.
- The feature's entrypoint exports `CONTAINER_HOST` and `DOCKER_HOST` only when they are not already set.

## Limitations

- This feature currently targets Fedora and RHEL-family images with `dnf`.
- Unlike the nested feature, this does not create an isolated container runtime inside the dev container. All container operations go through the host Podman service.
- Access to the mounted socket is equivalent to access to the host container engine, so do not treat this as a security boundary.

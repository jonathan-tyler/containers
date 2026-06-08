## Notes

- The feature prefers the least-surprising nested setup: privileged outer container, `fuse-overlayfs` storage, and isolated storage volumes.
- It writes `/etc/containers/containers.conf` and `/etc/containers/storage.conf` so the installed Podman uses settings that are friendlier to containerized execution.
- A `podman` user is created with subuid and subgid ranges, and the detected non-root devcontainer user also gets a range when possible.

## Limitations

- This feature currently targets Fedora and RHEL-family images with `dnf`.
- Privileged mode is the compatibility-first choice here. If you need a tighter security posture, you can drop down to custom `capAdd`, `securityOpt`, and device settings in your own `devcontainer.json`, following the Red Hat article.

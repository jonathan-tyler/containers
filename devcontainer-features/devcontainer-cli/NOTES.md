## Notes

- This feature installs only the `devcontainer` CLI and leaves Podman socket wiring to `podman-outside-of-podman`.
- The dependency is modeled in feature metadata, but the example configuration also lists both features explicitly to keep local path usage unambiguous.

## Limitations

- This feature currently targets Fedora and RHEL-family images with `dnf`.
- It expects either `npm` to already be present or `nodejs` installation from the base image repositories to provide it.

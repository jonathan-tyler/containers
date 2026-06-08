## Notes

- This feature installs only the OpenCode binary and leaves all user and project configuration to later setup steps.
- The installer downloads the Linux release tarball directly from GitHub releases and installs `opencode` into `/usr/local/bin`.

## Limitations

- This feature currently targets Fedora and RHEL-family images with `dnf`.
- The release archive naming is currently hardcoded for Linux `x64` and `arm64` builds.

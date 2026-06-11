## Notes

- This feature is intended for local code analysis and rewrite workflows.
- It avoids remote-access and host-diagnostic tools, which are reserved for `utils-ops`.

## Limitations

- This feature currently targets Fedora and RHEL-family images with `dnf`.
- `yamllint` is installed from RPM when available, otherwise via `pip`.

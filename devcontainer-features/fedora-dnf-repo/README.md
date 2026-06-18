# Fedora DNF Repo (`fedora-dnf-repo`)

Write the Fedora DNF/YUM repo file for dnf-based Fedora and RHEL-family images.

## Notes

- The feature currently targets `dnf` only.
- The repo definition is hardcoded for Fedora 42 with the same settings previously passed through JSON.
- It is intended for `utils-core` and similar consumers that need Fedora as a lower-priority fallback source.

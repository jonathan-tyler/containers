# Fedora DNF Repo (`fedora-dnf-repo`)

Write the Fedora DNF/YUM repo file used as a fallback for Hummingbird-only environments.

## Notes

- The feature writes `/etc/yum.repos.d/fedora.repo` only when `hummingbird` is the sole enabled repo.
- The repo definition is hardcoded for Fedora 42 with the same settings previously passed through JSON.
- It is intended for `utils-core` and similar consumers that need Fedora as a lower-priority fallback source.

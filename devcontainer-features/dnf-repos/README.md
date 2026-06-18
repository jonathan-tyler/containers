# DNF Repositories (`dnf-repos`)

Write one or more DNF/YUM repo files from declarative JSON definitions.

## Example Usage

```json
"features": {
  "ghcr.io/jonathan-tyler/containers/dnf-repos:0": {
    "REPOS_JSON": "[{\"id\":\"fedora\",\"name\":\"Fedora 42 - $basearch\",\"metalink\":\"https://mirrors.fedoraproject.org/metalink?repo=fedora-42&arch=$basearch\",\"enabled\":1,\"priority\":99,\"gpgcheck\":1,\"repo_gpgcheck\":0,\"gpgkey\":\"file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-42-$basearch\"}]"
  }
}
```

## Notes

- `id` becomes both the repo filename and the INI section name.
- Exactly one of `baseurl`, `metalink`, or `mirrorlist` is required for each repo object.
- The feature only writes repos when the current system has a single enabled repo named `hummingbird`, which keeps it suitable as a Fedora fallback in `utils-core`.

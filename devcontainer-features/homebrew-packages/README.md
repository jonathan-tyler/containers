# Homebrew Packages (`homebrew-packages`)

Install Homebrew formulae with a temporary Homebrew bootstrap, then remove the Homebrew manager files so the final image keeps the installed payloads without keeping the full Homebrew checkout around.

## Example Usage

```json
"features": {
  "ghcr.io/jonathan-tyler/containers/homebrew-packages:0": {
    "packages": "hello ripgrep"
  }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| packages | Space-delimited Homebrew formula names to install. | string |  |
| username | User that should own the temporary Homebrew tree while formulae are installed. | string | automatic |

## Notes

- The feature bootstraps Homebrew under `/home/linuxbrew/.linuxbrew`, installs the requested formulae, links any linked executables into `/usr/local/bin` and `/usr/local/sbin`, then removes the Homebrew manager checkout and caches.
- Formula payloads remain under `/home/linuxbrew/.linuxbrew` because that is where Homebrew installs Cellar and `opt` content on Linux.
- Automatic user detection prefers existing non-root users such as `vscode`, `node`, `codespace`, `devcontainer`, `nonroot`, and UID `65532` accounts before falling back to `root`.
- On Fedora and RHEL-family images, the feature uses `dnf` only when core Homebrew prerequisites such as `curl`, `git`, `file`, `tar`, `gzip`, `xz`, `procps`, or a user-switch utility are missing. If those prerequisites already exist, no package-manager bootstrap is needed.
- This feature uses the official Homebrew installer and does not depend on external devcontainer features or `ghcr` feature chaining.

## OS Support

This feature targets Linux containers. Fedora and RHEL-family images work best because `dnf` can install missing Homebrew prerequisites when needed.

## Reference

- https://brew.sh/
- https://github.com/meaningful-ooo/devcontainer-features/blob/main/src/homebrew/install.sh
- https://github.com/devcontainers-extra/features/blob/main/src/homebrew-package/install.sh

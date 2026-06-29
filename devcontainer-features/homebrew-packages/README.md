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
| cache_directory | Directory used for Homebrew bottle downloads during install. Point this at a persistent path if you want to reuse bottles between runs. | string | /tmp/homebrew-cache |

## Notes

- The feature bootstraps Homebrew under `/home/linuxbrew/.linuxbrew`, installs the requested formulae, links any linked executables into `/usr/local/bin` and `/usr/local/sbin`, then removes the Homebrew manager checkout and the default temporary cache.
- Set `cache_directory` to a stable path if you want to keep bottle downloads around for later runs; that path is left in place during cleanup.
- If Homebrew is already present in the image, the feature reuses that installation instead of bootstrapping a second copy.
- Formula payloads remain under `/home/linuxbrew/.linuxbrew` because that is where Homebrew installs Cellar and `opt` content on Linux.
- Automatic user detection prefers existing non-root users such as `vscode`, `node`, `codespace`, `devcontainer`, `nonroot`, and UID `65532` accounts before falling back to a temporary `linuxbrew` bootstrap user when the image only has `root`.
- On Ubuntu and RHEL-family images, the feature installs only the missing Homebrew prerequisites and, when necessary, creates a `linuxbrew` user so the upstream Homebrew installer can run as a real non-root account.
- Alpine images fail fast with a clear error because upstream Homebrew currently depends on glibc-backed portable Ruby or a system Ruby 4.0, which plain musl Alpine images do not provide.
- This feature uses the official Homebrew installer and does not depend on external devcontainer features or `ghcr` feature chaining.

## OS Support

This feature targets Linux containers. Ubuntu and RHEL-family images are supported. Alpine is detected explicitly and rejected with an upstream-constraint error instead of failing later during Homebrew bootstrap.

## Reference

- https://brew.sh/
- https://github.com/meaningful-ooo/devcontainer-features/blob/main/src/homebrew/install.sh
- https://github.com/devcontainers-extra/features/blob/main/src/homebrew-package/install.sh

# Homebrew Install (`homebrew-install`)

Install Homebrew and the distro prerequisites it needs under `/home/linuxbrew/.linuxbrew`, keep `brew` available on `PATH`, and optionally clean the manager checkout back out when you only want the prerequisite layer.

## Example Usage

```json
"features": {
  "ghcr.io/jonathan-tyler/containers/homebrew-install:0": {
    "username": "nonroot"
  }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| username | User that should own the temporary Homebrew tree while Homebrew is installed. | string | automatic |
| cache_directory | Directory used for Homebrew bottle downloads during bootstrap. Point this at a persistent path if you want to reuse bottles between runs. | string | /tmp/homebrew-cache |
| cleanupHomebrew | Remove the Homebrew manager and default cleanup artifacts after bootstrap. Leave this `false` when you want the feature to keep a working Homebrew install. | boolean | false |

## Notes

- The feature bootstraps Homebrew under `/home/linuxbrew/.linuxbrew`, links `brew` into `/usr/local/bin/brew`, and leaves the checkout in place by default.
- The feature installs only Homebrew and its distro prerequisites. It does not install formulae.
- Set `cache_directory` to a stable path if you want to keep bottle downloads around for later runs; that path is left in place during cleanup.
- Set `cleanupHomebrew` to `true` only when you explicitly want to remove the Homebrew manager checkout and default temporary cache after bootstrap.
- If Homebrew is already present in the image, the feature reuses that installation instead of bootstrapping a second copy.
- The feature requires a real named non-root passwd user. Numeric-only runtime users such as `65532` are rejected because upstream Homebrew postinstall behavior depends on a stable passwd-backed account.
- Automatic user detection prefers existing named non-root users such as `vscode`, `node`, `codespace`, `devcontainer`, `nonroot`, `podman`, and `ubuntu`.
- If your image does not already define a suitable user, create one in the image itself or add the repo's `nonroot-user` feature before `homebrew-install`.
- Alpine images fail fast with a clear error because upstream Homebrew currently depends on glibc-backed portable Ruby or a system Ruby 4.0, which plain musl Alpine images do not provide.
- This feature uses the official Homebrew installer and does not depend on external devcontainer features or `ghcr` feature chaining.

## OS Support

This feature targets Linux containers. Ubuntu and Debian-family images install `build-essential` and `patch` plus missing core prerequisites, Fedora and RHEL-family images install `gcc`, `gcc-c++`, `glibc-devel`, `libstdc++-devel`, `make`, and `patch` plus missing core prerequisites, and all supported Linux images must provide glibc 2.39 or newer. Alpine is detected explicitly and rejected with an upstream-constraint error instead of failing later during Homebrew bootstrap.

## Reference

- https://brew.sh/
- https://github.com/meaningful-ooo/devcontainer-features/blob/main/src/homebrew/install.sh

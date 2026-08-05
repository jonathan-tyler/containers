# Containers

Containerized applications, Dev Container resources, and supporting automation.

## Containerized Applications

- 🎬 [yt-dlp](./images/yt-dlp): Hummingbird-based yt-dlp utility image published to GHCR.

## Dev Containers

### Dev Container Features

- ✨ [aspire-cli](./devcontainer-features/src/aspire-cli): installs the Aspire CLI with an available supported package manager.
- 🍺 [homebrew-install](./devcontainer-features/src/homebrew-install): installs Homebrew and its Linux prerequisites.
- 📦 [homebrew-packages](./devcontainer-features/src/homebrew-packages): installs selected Homebrew formulae for a non-root user.
- 👤 [nonroot-user](./devcontainer-features/src/nonroot-user): creates a named non-root user in minimal images.
- 📦 [podman-in-podman](./devcontainer-features/src/podman-in-podman): runs Podman inside a Dev Container with isolated storage.

### Dev Container Base Images

- 🍺 [`core-runtime:latest-homebrew`](./devcontainer-features/test/homebrew-install/feature-ci-base/Containerfile): Hummingbird `core-runtime` builder image with Homebrew preinstalled, published to GHCR.

### Dev Container Samples

- 🍻 [homebrew-into-distroless](./devcontainer-samples/homebrew-into-distroless): copies a Homebrew-installed package from a builder into a distroless runtime image.
- 🗄️ [mssql-sidecar](./devcontainer-samples/mssql-sidecar): runs SQL Server beside a minimal workspace container.
- 📦 [rootless-podman-in-rootless-podman](./devcontainer-samples/podman-in-podman/rootless-podman-in-rootless-podman): compares static and host-UID-independent nested rootless Podman configurations.
- 📨 [smtp4dev](./devcontainer-samples/smtp4dev): runs smtp4dev beside a minimal workspace container.
- 🦑 [squid-proxy](./devcontainer-samples/squid-proxy): runs a Squid proxy beside a workspace container and tests its allowlist.

## Development

See [Development](./docs/development.md) for local feature validation.

## Troubleshooting

See [Troubleshooting](./docs/troubleshooting.md) for known issues and fixes.

# Development

Use the repository's local tooling to validate Dev Container features before publishing them.

## Local Feature Validation

- Use `.devcontainer/feature-ci/devcontainer.json` for a workspace that can run feature tests and pre-publish checks before pushing.
- Start it with `dev up --overlay none --config .devcontainer/feature-ci/devcontainer.json`, or open that configuration directly in VS Code.
- Install `just`, `act`, `podman`, `devcontainer`, and `jq` in that environment before running the local commands.
- Run `just hooks` once in each checkout so Git uses the repository-managed `.githooks/` directory.
- Run `just prepare` to stage a disposable feature CI workspace and verify the toolchain.
- Run `just bump-feature-version <feature> <patch|minor|major|set X.Y.Z>` after choosing the semantic-version bump for a feature source change.
- Run `just check-feature-version-bumps` to validate staged feature source changes before committing.
- Run `just ci` to execute `.github/workflows/test.yaml` locally through `act`.
- Run `just feature homebrew-packages` to test one feature and its scenarios locally.
- Run `just podman-in-podman-smoke` to exercise the host-side `devcontainer up` and `devcontainer exec` smoke path for the `podman-in-podman` feature through the local Docker-to-Podman shim.
- Run `just publish-check` to package the features locally without publishing them.
- Run `just all` to execute both the local workflow simulation and the publish packaging check.

## Implementation Notes

- `just ci` and `just job ...` use `.github/workflows/test.yaml` directly as the source of truth.
- `just feature ...` and `just publish-check` are local developer conveniences around `devcontainer features test` and `devcontainer features package`.
- The packaging check generates `homebrew-packages-additional` from `homebrew-packages`, matching the release workflow while keeping one source feature to maintain.
- Homebrew feature tests use a prewarmed CI base image and shared bottle cache so bootstrap and downloads can be reused across scenarios and local runs.
- Local commands stage their temporary workspace in a `mktemp` directory and clean it up automatically.
- `act` defaults to `ghcr.io/catthehacker/ubuntu:act-latest` for the `ubuntu-latest` runner image. Set `ACT_RUNNER_IMAGE` to override it.
- The local `act` flow expects a Podman-backed Docker API socket at `${XDG_RUNTIME_DIR}/podman/podman.sock`. If the socket is missing, `just` starts `podman system service` there and reuses that path for subsequent runs.
- The local `devcontainer` flow places a Docker compatibility shim at the disposable workspace's `bin/docker` path so `devcontainer features test` can communicate with Podman without changing workflow commands.
- Nested container work in the feature CI Dev Container uses the repository's `--userns=keep-id`, FUSE, TUN, and seccomp settings. These settings are convenient for local validation but reduce the isolation normally provided by a Dev Container.

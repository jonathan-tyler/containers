# Containers

Container images, automation, templates, and samples

## Resources
- 📦 [local-registry](./local-registry): local registry install and systemd bootstrap.
- 🧱 [dev-base](./images/dev-base): base image and local registry bootstrap.
- 🛠️ [monolith-dev](./images/monolith-dev): polyglot devcontainer image for mixed workspace development.
- 🐹 [golang-dev](./images/golang-dev): Go devcontainer image.
- 🟢 [javascript-dev](./images/javascript-dev): JavaScript devcontainer image.
- 🐍 [python-dev](./images/python-dev): Python devcontainer image.
- 🔷 [typescript-dev](./images/typescript-dev): TypeScript devcontainer image layered on the JavaScript dev image.
- 🔷 [dotnet-dev](./images/dotnet-dev): .NET devcontainer image.
- 🗄️ [devcontainer-samples/mssql-dev](./devcontainer-samples/mssql-dev): compose-backed SQL Server devcontainer sample.
- 🧰 [devcontainer-samples/podman-in-podman](./devcontainer-samples/podman-in-podman): single-container sample with the nested Podman feature and required runtime arguments.
- 📨 [devcontainer-samples/smtp4dev](./devcontainer-samples/smtp4dev): compose-backed smtp4dev devcontainer sample.

## Usage

- To set up the local registry, run `./local-registry/install.sh`. It creates or starts the registry container and enables a lingering systemd user service so it comes back automatically.
- To build and publish images, run `./local-registry/build-images.sh --version X.Y.Z`.

## Local Feature Validation

- Use `.devcontainer/feature-ci/devcontainer.json` when you want a workspace that can run the feature test and pre-publish checks before pushing.
- Start it with `dev up --overlay none --config .devcontainer/feature-ci/devcontainer.json`, or open that config directly in VS Code.
- Install `just`, `act`, `podman`, `devcontainer`, and `jq` in that environment before running the local commands.
- Run `just prepare` once if you want to refresh the scratch workspace manually.
- Run `just ci` to execute `.github/workflows/test.yaml` locally through `act`.
- Run `just feature homebrew-packages` to test one edited feature locally, including its scenarios. This is the direct feature-validation path for work that is not covered by the current workflow matrix.
- Run `just publish-check` to package `devcontainer-features/` locally without publishing anything. This is the local equivalent of the release workflow's packaging step.
- Run `just all` to execute both the local workflow simulation and the publish packaging check.
- `just ci` and `just job ...` keep `.github/workflows/test.yaml` as the source of truth. They point `act` at that workflow file directly instead of wrapping the workflow logic in another shell runner.
- `just feature ...` and `just publish-check` are local-only developer conveniences. They keep the existing `devcontainer features test` and `devcontainer features package` behavior without changing the GitHub workflow.
- The local commands write their temporary `src` and `test` layout, Docker-to-Podman shim, package output, and any fallback Podman runtime state under `.scratch/feature-ci/`, which is already ignored by git.
- `act` defaults to `ghcr.io/catthehacker/ubuntu:act-latest` for the `ubuntu-latest` runner image. Override it with `ACT_RUNNER_IMAGE` if you need a different local image.
- The local `act` flow expects a Podman-backed Docker API socket at `${XDG_RUNTIME_DIR}/podman/podman.sock`. If that socket is missing, `just` starts `podman system service` there and reuses the same path for repeated runs.
- The local `devcontainer` flow uses a Docker compatibility shim under `.scratch/feature-ci/bin/docker` so `devcontainer features test` can keep talking to Podman without changing the workflow commands.
- Inside the `feature-ci` devcontainer you are still doing nested container work through the mounted host Podman stack, with the repo's existing `--userns=keep-id`, FUSE, and TUN settings. That is convenient for local validation, but it keeps the same reduced isolation trade-off as before.

## Shared Toolchains

- Focused images and `monolith-dev` both consume these scripts so version pins and install behavior stay aligned.
- Keep image-specific policy in the image `Containerfile`; keep toolchain installation details in the shared scripts.
- Keep shared images generic: install tools and shell capability there, but apply personal dotfiles and prompt config at devcontainer runtime instead of baking host-specific files into image builds.

`mssql-dev` and `smtp4dev` are compose-backed devcontainer samples. `podman-in-podman` is a single-container sample that applies the feature with the required nested-container run arguments. See [devcontainer-samples/mssql-dev/README.md](./devcontainer-samples/mssql-dev/README.md), [devcontainer-samples/podman-in-podman/README.md](./devcontainer-samples/podman-in-podman/README.md), and [devcontainer-samples/smtp4dev/README.md](./devcontainer-samples/smtp4dev/README.md).

## Notes

- The workspace dev container mounts the host Podman socket so image build and container registry tasks can run inside a more isolated tooling environment, with the understanding that this weakens the isolation a devcontainer would normally provide. This is a repo-specific convenience, not a recommended general pattern.

## Troubleshooting

### VS Code rewrites `localhost:5000` image references

If a `devcontainer.json` uses `localhost:5000/...` with `updateRemoteUserUID` enabled, Dev Containers can rewrite that image name to `localhost/localhost:5000/...` during the temporary UID-adjustment build. Podman then rejects the rewritten reference.

Use `127.0.0.1:5000/...` instead.

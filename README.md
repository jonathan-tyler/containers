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
- ✨ [devcontainer-samples/dotnet-aspire](./devcontainer-samples/dotnet-aspire): Aspire sample that launches a hello-world container through AppHost.
- 🗄️ [devcontainer-samples/mssql-dev](./devcontainer-samples/mssql-dev): compose-backed SQL Server devcontainer sample.
- 📨 [devcontainer-samples/smtp4dev](./devcontainer-samples/smtp4dev): compose-backed smtp4dev devcontainer sample.

## Usage

- To set up the local registry, run `./local-registry/install.sh`. It creates or starts the registry container and enables a lingering systemd user service so it comes back automatically.
- To build and publish images, run `./local-registry/build-images.sh --version X.Y.Z`.

## Local Feature Validation

- Use `.devcontainer/feature-ci/devcontainer.json` when you want a workspace that can run the feature test and pre-publish checks before pushing.
- Start it with `dev up --overlay none --config .devcontainer/feature-ci/devcontainer.json`, or open that config directly in VS Code.
- Inside that container, run `bash scripts/feature-ci/run.sh prepare` once if you want to refresh the scratch workspace manually.
- Run `bash scripts/feature-ci/run.sh ci` to mirror the current `.github/workflows/test.yaml` jobs locally.
- Run `bash scripts/feature-ci/run.sh job test-utils-core` to replay a single workflow job.
- Run `bash scripts/feature-ci/run.sh feature homebrew-packages` to test one edited feature locally, including its scenarios. This is useful for features that are not yet part of the current workflow matrix.
- Run `bash scripts/feature-ci/run.sh publish-check` to package `devcontainer-features/` locally without publishing anything. This is the local equivalent of the release workflow's packaging step.
- Run `bash scripts/feature-ci/run.sh all` to execute both the local CI pass and the publish packaging check.
- The runner writes its temporary `src` and `test` layout, Docker-to-Podman shim, and package output under `.scratch/feature-ci/`, which is already ignored by git.

## Shared Toolchains

- Focused images and `monolith-dev` both consume these scripts so version pins and install behavior stay aligned.
- Keep image-specific policy in the image `Containerfile`; keep toolchain installation details in the shared scripts.
- Keep shared images generic: install tools and shell capability there, but apply personal dotfiles and prompt config at devcontainer runtime instead of baking host-specific files into image builds.

`mssql-dev` and `smtp4dev` are compose-backed devcontainer samples. See [devcontainer-samples/mssql-dev/README.md](./devcontainer-samples/mssql-dev/README.md) and [devcontainer-samples/smtp4dev/README.md](./devcontainer-samples/smtp4dev/README.md).

## Notes

- The workspace dev container mounts the host Podman socket so image build and container registry tasks can run inside a more isolated tooling environment, with the understanding that this weakens the isolation a devcontainer would normally provide. This is a repo-specific convenience, not a recommended general pattern.

## Troubleshooting

### VS Code rewrites `localhost:5000` image references

If a `devcontainer.json` uses `localhost:5000/...` with `updateRemoteUserUID` enabled, Dev Containers can rewrite that image name to `localhost/localhost:5000/...` during the temporary UID-adjustment build. Podman then rejects the rewritten reference.

Use `127.0.0.1:5000/...` instead.

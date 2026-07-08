# homebrew-distroless

Containerfile-only devcontainer sample that installs a Homebrew package in a builder stage and copies the resulting tree into a distroless `core-runtime` image.

Open this folder in Dev Containers. The builder stage starts from `homebrew:latest-builder`, installs `hello`, and the runtime stage copies the Homebrew prefix into `registry.access.redhat.com/hi/core-runtime:latest`.

## Files

- `.devcontainer/devcontainer.json`: devcontainer entry point.
- `Containerfile`: multi-stage build that installs Homebrew `hello` and copies it into the runtime image.

## Test

- From inside the dev container, run `hello`.

## Notes

- Builder image: `homebrew:latest-builder`
- Runtime image: `registry.access.redhat.com/hi/core-runtime:latest`
- Installed package: `hello`

# dotnet-aspire

Devcontainer sample for Aspire on the Red Hat .NET SDK image.

## What it does

- Uses `registry.access.redhat.com/hi/dotnet-sdk:latest-builder`.
- Enables the `podman-in-podman` feature so AppHost can orchestrate containers.
- Sets `ASPIRE_CONTAINER_RUNTIME=podman` in the devcontainer environment.
- Pins `Aspire.ProjectTemplates` and `Aspire.Hosting.AppHost` to `13.4.4`, the latest NuGet release at setup time.
- Runs a `registry.access.redhat.com/hi/core-runtime:latest-builder` container that prints `hello world`.

## Run

```bash
dotnet run
```

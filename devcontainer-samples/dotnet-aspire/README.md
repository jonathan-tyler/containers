# dotnet-aspire

Devcontainer sample for Aspire on the Red Hat .NET SDK image.

## What it does

- Uses `registry.access.redhat.com/hi/dotnet-sdk:latest-builder`.
- Enables the `podman-in-podman` feature so AppHost can orchestrate containers.
- Enables the `ghcr.io/jonathan-tyler/containers/dotnet-aspire-cli:0` feature.
- Sets `ASPIRE_CONTAINER_RUNTIME=podman` in the devcontainer environment.
- Uses `--userns=keep-id:uid=65532,gid=0` so nested rootless Podman is healthy with the hardened image user.
- Uses a host `initializeCommand` to make the sample workspace group-writable for the hardened image user.
- Pins `Aspire.ProjectTemplates` and `Aspire.Hosting.AppHost` to `13.4.4`, the latest NuGet release at setup time.
- Defines an Aspire AppHost container resource for `registry.access.redhat.com/hi/core-runtime:latest-builder` that runs `echo hello world && sleep 3600`.

## Run

```bash
dotnet run
```

## Note

- The devcontainer now runs nested rootless Podman successfully with the hardened Red Hat image user.
- On this host, Aspire's native `AddContainer(...)` path still creates a rootless Podman container with `bridge` networking, which leaves the inner container in `Created` with `netavark: set sysctl net/ipv4/ip_forward: IO error: Read-only file system`.

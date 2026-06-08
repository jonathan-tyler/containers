# Dev Container CLI (`devcontainer-cli`)

Install the Dev Container CLI for Podman-backed devcontainer workflows.

## Example Usage

```json
"features": {
  "./devcontainer-features/podman-outside-of-podman": {},
  "./devcontainer-features/devcontainer-cli": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| VERSION | Dev Container CLI version to install. Use `latest` for the current npm release. | string | latest |

## Notes

- This feature is intended to be used with `podman-outside-of-podman` so `devcontainer` commands can talk to the mounted host Podman socket.
- The installer uses the npm package `@devcontainers/cli`.
- In Podman-based workflows, use `devcontainer --docker-path podman` unless your environment already aliases Docker-compatible tooling appropriately.

## OS Support

This feature currently targets Fedora and RHEL-family images with `dnf`.

## Reference

- `/home/him/setup/install-apps/shared/32-devcontainer.sh`
- `https://code.visualstudio.com/docs/devcontainers/devcontainer-cli`

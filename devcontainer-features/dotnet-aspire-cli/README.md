# dotnet Aspire CLI (`dotnet-aspire-cli`)

Install the Aspire CLI with the official installer.

## Example Usage

```json
"features": {
  "ghcr.io/jonathan-tyler/containers/dotnet-aspire-cli:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| INSTALLCLI | Whether to install the Aspire CLI. | boolean | true |

## Notes

- The feature copies `aspire` into `/usr/local/bin` after installation so it is available in non-interactive shells.
- Set `INSTALLCLI` to `false` to skip the CLI install step.

## OS Support

This feature currently targets apt-get and dnf based images.

## Reference

- https://github.com/microsoft/aspire-devcontainer-feature
- https://aspire.dev

# Aspire CLI (`aspire-cli`)

Install the Aspire CLI with the first supported package manager already present in the image. The feature checks `mise` first, then the `dotnet` CLI for the NuGet-based global tool install, and finally `npm`.

## Example Usage

```json
"features": {
  "ghcr.io/jonathan-tyler/containers/aspire-cli:0": {}
}
```

## Options

This feature has no options.

## Notes

- The feature does not bootstrap a package manager. It only uses one that is already available in the image.
- If `aspire` is already installed and working, the feature exits early and leaves the existing installation in place.
- `mise` installs `aspire` first when present.
- If `mise` is absent and `dotnet` is available, the feature installs the `Aspire.Cli` global tool via the `dotnet` CLI.
- If neither `mise` nor `dotnet` is available, the feature falls back to `npm install -g @microsoft/aspire-cli`.
- The final `aspire` executable is linked into `/usr/local/bin/aspire`.

## OS Support

This feature currently targets Linux containers that already include `mise`, `dotnet`, or `npm`.

## Reference

- https://aspire.dev/get-started/install-cli/

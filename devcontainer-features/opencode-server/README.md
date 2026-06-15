# OpenCode Server (`opencode-server`)

Install OpenCode for headless HTTP server usage with `opencode serve`.

## Example Usage

```json
"features": {
  "ghcr.io/jonathan-tyler/containers/opencode-server:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| VERSION | OpenCode version to install. Use `latest` for the current release. | string | latest |

## Notes

- Start the server with `opencode serve`.
- By default the server listens on `127.0.0.1:4096`.
- Protect the server with HTTP basic auth by setting `OPENCODE_SERVER_PASSWORD`. The username defaults to `opencode`, or you can override it with `OPENCODE_SERVER_USERNAME`.
- The OpenAPI spec is exposed at `http://<hostname>:<port>/doc`.
- This feature installs the OpenCode binary only. It does not install provider credentials or user config.

## OS Support

This feature currently targets Fedora and RHEL-family images with `dnf`.

## Reference

- https://opencode.ai/docs/server/

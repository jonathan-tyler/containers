# squid-proxy

Compose-backed devcontainer sample that pairs a workspace container with a squid proxy sidecar.

Open this folder in Dev Containers or run `dev up`. The workspace container points its proxy variables at squid and runs a startup test that confirms `example.net` is blocked while `example.com` is allowed.

## Files

- `.devcontainer/devcontainer.json`: devcontainer entry point.
- `docker-compose.yaml`: workspace and squid services.
- `workspace/Containerfile`: workspace image build with `curl`.
- `workspace/test.sh`: proxy allowlist test run on startup.
- `squid/Containerfile`: multi-stage squid image build from `ghcr.io/jonathan-tyler/containers/core-runtime:latest-homebrew` into a distroless runtime.
- `squid/squid.conf`: squid access rules for the sample.
- `squid/allowed-domains.txt`: sample hostname allowlist consumed by Squid.

## Test

- The workspace container runs `bash workspace/test.sh` on start.
- The script expects `curl --fail http://example.net/` to fail and `curl --fail http://example.com/` to pass through Squid.
- To allow another hostname, add it to `squid/allowed-domains.txt`.

## Notes

- Workspace image: `registry.access.redhat.com/hi/core-runtime:latest-builder`
- Proxy image: `registry.access.redhat.com/hi/core-runtime:latest` copied from `ghcr.io/jonathan-tyler/containers/core-runtime:latest-homebrew`
- Proxy port published on the host: `3128`
- Workspace stays on the internal app network.
- Sample allowlist entry: `example.com`.

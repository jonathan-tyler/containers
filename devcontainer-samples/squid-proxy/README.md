# squid-proxy

Compose-backed devcontainer sample that pairs a workspace container with a squid proxy sidecar, a curl client sidecar, and a tiny nginx target service.

Open this folder in Dev Containers. The workspace container points its proxy variables at squid, and the `curl` sidecar checks that `example.net` is blocked while `example.com` is allowed.

## Files

- `.devcontainer/devcontainer.json`: devcontainer entry point.
- `docker-compose.yaml`: workspace, curl, proxy, and target services.
- `workspace/Containerfile`: workspace image build.
- `curl/Containerfile`: curl client image build.
- `curl/test.sh`: proxy allowlist test.
- `squid/Containerfile`: multi-stage squid image build from `ghcr.io/jonathan-tyler/containers/core-runtime:latest-homebrew` into a distroless runtime.
- `squid/squid.conf`: squid access rules for the sample.
- `squid/allowed-domains.txt`: sample hostname allowlist consumed by Squid.
- `web/Containerfile`: nginx target image build.
- `web/index.html`: target page served by nginx.

## Test

- From the curl sidecar, run `/usr/local/bin/test.sh`.
- The script expects `curl --fail http://example.net/` to fail and `curl --fail http://example.com/` to pass through Squid.
- To allow another hostname, add it to `squid/allowed-domains.txt`.

## Notes

- Workspace image: `registry.access.redhat.com/hi/core-runtime:latest-builder`
- Proxy image: `registry.access.redhat.com/hi/core-runtime:latest` copied from `ghcr.io/jonathan-tyler/containers/core-runtime:latest-homebrew`
- Target image: built from `nginx:alpine`
- Proxy port published on the host: `3128`
- Workspace, curl, and target services stay on the internal app network.
- Sample allowlist entry: `example.com`.

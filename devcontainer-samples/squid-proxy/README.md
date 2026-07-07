# squid-proxy

Compose-backed devcontainer sample that pairs a workspace container with a squid proxy sidecar and a tiny nginx target service.

Open this folder in Dev Containers. The workspace container ships with `curl`, points its proxy variables at squid, and can reach the target service through the proxy with `curl --fail http://web/`.

## Files

- `.devcontainer/devcontainer.json`: devcontainer entry point.
- `docker-compose.yml`: workspace, proxy, and target services.
- `workspace/Containerfile`: workspace image build that adds `curl`.
- `squid/Containerfile`: squid image build.
- `squid/squid.conf`: squid access rules for the sample.
- `web/Containerfile`: nginx target image build.
- `web/index.html`: target page served by nginx.

## Test

- From inside the workspace container, run `curl --fail http://web/`.
- From the host, run `curl -x http://localhost:3128 --fail http://web/`.
- From the host, `curl -x http://localhost:3128 --fail http://1.1.1.1/` should fail.

## Notes

- Workspace image: `registry.access.redhat.com/hi/core-runtime:latest-builder`
- Proxy image: `registry.access.redhat.com/hi/core-runtime:latest`
- Target image: built from `nginx:alpine`
- Proxy port published on the host: `3128`
- Workspace and target services stay on the internal app network.

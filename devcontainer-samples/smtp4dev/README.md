# smtp4dev

Compose-backed devcontainer sample that pairs a dummy `core-runtime` workspace container with an smtp4dev sidecar.

Open this folder in Dev Containers. The workspace container uses `registry.access.redhat.com/hi/core-runtime:latest`, and smtp4dev runs alongside it in the compose network.

## Files

- `.devcontainer/devcontainer.json`: devcontainer entry point.
- `docker-compose.yml`: workspace container and smtp4dev sidecar.

## Connection Details

- From inside the workspace container, send mail to `smtp4dev:25` and open the inbox at `http://smtp4dev:80`.
- From the host, the sample publishes SMTP on `localhost:1025` and the inbox UI on `http://localhost:8025`.

## Notes

- Image: `rnwood/smtp4dev:latest`
- Persistent storage: named volume `smtp4dev-data`
- Workspace container: `registry.access.redhat.com/hi/core-runtime:latest`

# mssql-dev

Compose-backed devcontainer sample that pairs a dummy `core-runtime` workspace container with a SQL Server sidecar.

Open this folder in Dev Containers. The workspace container uses `registry.access.redhat.com/hi/core-runtime:latest`, and the SQL Server service runs alongside it in the compose network.

## Files

- `.devcontainer/devcontainer.json`: devcontainer entry point.
- `docker-compose.yml`: workspace container and SQL Server sidecar.

## Connection Details

- From inside the workspace container, connect to SQL Server at `mssql-dev:1433`.
- From the host, the sample publishes SQL Server on `localhost,14333`.
- `MSSQL_SA_PASSWORD` is set in `docker-compose.yml` for the sample. Edit that file if you want to change it.

## Notes

- Image: `mcr.microsoft.com/mssql/server:2022-latest`
- Edition: `Developer`
- Persistent storage: named volume `mssql-dev-data`
- Workspace container: `registry.access.redhat.com/hi/core-runtime:latest`

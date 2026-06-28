FROM docker.io/library/fedora:42

RUN install -d /usr/local/bin && \
    cat <<'EOF' >/usr/local/bin/dotnet
#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" != "tool" ]; then
    exit 1
fi

subcommand="${2:-}"
shift 2
tool_path=""
package_name=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --tool-path)
            tool_path="$2"
            shift 2
            ;;
        *)
            package_name="$1"
            shift
            ;;
    esac
done

if [ -z "${tool_path}" ] || [ "${package_name}" != "Aspire.Cli" ]; then
    exit 1
fi

case "${subcommand}" in
    install|update)
        install -d "${tool_path}"
        cat <<'INNER' >"${tool_path}/aspire"
#!/usr/bin/env bash
printf '1.0.0-mock-nuget\n'
INNER
        chmod +x "${tool_path}/aspire"
        printf 'nuget' >/tmp/aspire-installer
        ;;
    *)
        exit 1
        ;;
esac
EOF

RUN chmod +x /usr/local/bin/dotnet && \
    cat <<'EOF' >/usr/local/bin/npm
#!/usr/bin/env bash
printf 'npm should not have been selected\n' >&2
exit 1
EOF

RUN chmod +x /usr/local/bin/npm

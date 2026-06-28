FROM docker.io/library/fedora:42

RUN install -d /usr/local/bin /tmp/mock-mise/installs/aspire/1.0.0/bin && \
    cat <<'EOF' >/usr/local/bin/mise
#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
    use)
        if [ "${2:-}" != "-g" ] || [ "${3:-}" != "aspire" ]; then
            exit 1
        fi

        cat <<'INNER' >/tmp/mock-mise/installs/aspire/1.0.0/bin/aspire
#!/usr/bin/env bash
printf '1.0.0-mock-mise\n'
INNER
        chmod +x /tmp/mock-mise/installs/aspire/1.0.0/bin/aspire
        printf 'mise' >/tmp/aspire-installer
        ;;
    where)
        if [ "${2:-}" != "aspire" ]; then
            exit 1
        fi

        printf '/tmp/mock-mise/installs/aspire/1.0.0\n'
        ;;
    *)
        exit 1
        ;;
esac
EOF

RUN chmod +x /usr/local/bin/mise && \
    cat <<'EOF' >/usr/local/bin/dotnet
#!/usr/bin/env bash
printf 'dotnet should not have been selected\n' >&2
exit 1
EOF

RUN chmod +x /usr/local/bin/dotnet && \
    cat <<'EOF' >/usr/local/bin/npm
#!/usr/bin/env bash
printf 'npm should not have been selected\n' >&2
exit 1
EOF

RUN chmod +x /usr/local/bin/npm

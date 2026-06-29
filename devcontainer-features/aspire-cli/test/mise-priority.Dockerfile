FROM registry.access.redhat.com/hi/dotnet-sdk:latest-builder

USER root

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

RUN chmod +x /usr/local/bin/mise

USER 65532

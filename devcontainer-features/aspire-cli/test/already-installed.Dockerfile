FROM registry.access.redhat.com/hi/nodejs:latest-builder

USER root

RUN install -d /usr/local/bin && \
    cat <<'EOF' >/usr/local/bin/aspire
#!/usr/bin/env bash
printf '0.0.0-preinstalled\n'
EOF

RUN chmod +x /usr/local/bin/aspire

USER 65532

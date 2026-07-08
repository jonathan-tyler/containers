FROM registry.access.redhat.com/hi/nodejs:latest-builder

USER root

RUN dnf -y install --setopt=install_weak_deps=False shadow-utils && \
    useradd --create-home --uid 1000 --home-dir /home/nonroot --shell /bin/bash nonroot && \
    dnf clean all

RUN install -d /usr/local/bin && \
    cat <<'EOF' >/usr/local/bin/aspire
#!/usr/bin/env bash
printf '0.0.0-preinstalled\n'
EOF

RUN chmod +x /usr/local/bin/aspire

USER nonroot

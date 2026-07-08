FROM registry.access.redhat.com/hi/core-runtime:latest-builder

USER root
RUN dnf -y install --setopt=install_weak_deps=False shadow-utils \
    && useradd --create-home --home-dir /home/nonroot --shell /bin/bash nonroot \
    && dnf clean all

RUN mkdir -p /opt/existing-brew-root/bin

COPY brew /opt/existing-brew-root/bin/brew
COPY curl /usr/local/bin/curl

RUN chmod 0755 /opt/existing-brew-root/bin/brew /usr/local/bin/curl

ENV PATH="/opt/existing-brew-root/bin:${PATH}"
USER 65532

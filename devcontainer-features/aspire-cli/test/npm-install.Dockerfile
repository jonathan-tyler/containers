FROM registry.access.redhat.com/hi/nodejs:latest-builder

USER root

RUN dnf -y install --setopt=install_weak_deps=False libicu && \
    dnf clean all

USER 65532

FROM registry.access.redhat.com/hi/core-runtime:latest-builder

USER root

RUN mkdir -p /run/podman \
    && printf 'sentinel\n' >/run/podman/podman.sock

USER 65532

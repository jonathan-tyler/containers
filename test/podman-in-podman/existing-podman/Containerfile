FROM registry.access.redhat.com/hi/core-runtime:latest-builder

USER root

RUN mkdir -p /opt/existing-podman-root/bin /usr/local/bin

COPY dnf /usr/local/bin/dnf
COPY podman /opt/existing-podman-root/bin/podman
COPY fuse-overlayfs /opt/existing-podman-root/bin/fuse-overlayfs
COPY slirp4netns /opt/existing-podman-root/bin/slirp4netns
COPY newuidmap /opt/existing-podman-root/bin/newuidmap
COPY newgidmap /opt/existing-podman-root/bin/newgidmap

RUN chmod 0755 \
    /usr/local/bin/dnf \
    /opt/existing-podman-root/bin/podman \
    /opt/existing-podman-root/bin/fuse-overlayfs \
    /opt/existing-podman-root/bin/slirp4netns \
    /opt/existing-podman-root/bin/newuidmap \
    /opt/existing-podman-root/bin/newgidmap

ENV PATH="/opt/existing-podman-root/bin:/usr/local/bin:${PATH}"

USER 65532

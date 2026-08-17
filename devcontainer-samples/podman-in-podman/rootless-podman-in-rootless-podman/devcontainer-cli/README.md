# Nested Dev Container CLI with Rootless Podman

This sample preserves the `dynamic-uid/` outer user-namespace design, installs
Dev Container CLI `0.88.0` in that unprivileged outer container, and uses the
CLI with nested rootless Podman to build and run an inner runtime-echo Dev
Container.

The accepted `dynamic-uid/` sample remains unchanged. This sibling reuses its
subordinate-ID preflight, nested mapping test, Podman installer, and container
configuration as the baseline before exercising the additional CLI layer.

## What the sample does

Host-side `just test-podman`:

1. Runs the dynamic-UID host and subordinate-ID preflight.
2. Builds and launches this outer Dev Container through host rootless Podman.
3. Verifies the dynamic-UID nested Podman mapping and baseline runtime.
4. Uses the Dev Container CLI installed in the outer container with
   `--docker-path podman`.
5. Builds and starts `inner-devcontainer/.devcontainer/devcontainer.json`.
6. Reads the inner configuration's runtime-echo result, verifies the exact
   output `nested podman ok`, and removes the exact inner container.

It does not mount a host engine socket, use privileged mode, add capabilities,
expose `/dev/fuse`, or prune unrelated engine state.

## Prerequisites

The host requirements are the same as `dynamic-uid/`:

- a non-root Linux `x86_64` user;
- rootless Podman `5.8.2`;
- Dev Container CLI `0.88.0`;
- Just `1.58.0`; and
- one contiguous subordinate UID and GID range of at least 65,536 IDs.

The outer image installs Hummingbird Podman `6.0.2`, Node.js, npm, and Dev
Container CLI `0.88.0`. The temporary Fedora 43 package source retains the
baseline sample's documented `gpgcheck=0` limitation and must not be adopted for
production without installing and trusting the Fedora signing key.

Run from this directory:

```sh
just test-podman
```

Expected standard output is exactly:

```text
nested podman ok
```

Ignored diagnostics are written under `.devcontainer/evidence/`. They can
contain local identities, paths, container IDs, and image metadata.

## Inner runtime restrictions

The inner `devcontainer.json` passes these arguments to nested Podman:

```text
--network=none
--cgroups=disabled
--uts=host
```

The UTS setting shares the outer container's private UTS namespace, not the
host UTS namespace. It avoids the nested `sethostname: Operation not permitted`
failure without adding a capability. Nested storage remains on the baseline's
slower but narrower `vfs` driver.

# Nested Rootless Podman Dev Container Example

This example maps a variable non-root host identity to a fixed development user and runs rootless Podman inside that unprivileged Dev Container.

## What this example proves

Host-side `just test-podman` performs the complete test:

1. It verifies a non-root host identity, one contiguous subordinate UID and GID
   range, the tested architecture, rootless Podman, Just, and the Dev Container
   CLI.
2. It launches the outer development container with the Dev Container CLI and
   explicitly selects Podman as the CLI-compatible container runtime.
3. It enters the outer container through `devcontainer exec`.
4. The nested rootless engine pulls and starts a pinned Hummingbird
   `core-runtime` payload.
5. The inner container prints exactly `nested podman ok`, has networking and
   cgroup management disabled, and is removed after execution.
6. The run stores ignored diagnostic evidence under `.devcontainer/evidence/`.

It does **not** mount a host Podman or Docker socket, use privileged mode, add
`SYS_ADMIN` or `MKNOD`, expose `/dev/fuse`, run host Podman through `sudo`, or
prune unrelated host state.

## Tested prerequisites

This example supports a nonzero host UID and primary GID with exactly one
contiguous subordinate UID range and one contiguous subordinate GID range. Each
range must contain at least 65,536 IDs; its physical host-side start may vary.
It retains these tested software constraints:

- Linux `x86_64` on a WSL2 kernel;
- rootless Podman `5.8.2`;
- Dev Container CLI `0.88.0`; and
- Just `1.58.0`.

The image installs Hummingbird Podman `6.0.2`. At the current live-repository
verification, Fedora 43 supplies only the remaining `yajl` dependency gap.

Container UID `1000` and GID `1001` remain fixed image identities. Explicit
`keep-id` maps the invoking host user and primary group into those IDs. The
example does not edit host accounts or subordinate-ID configuration.

Run from the directory containing this README:

```sh
just test-podman
```

Expected standard output is exactly:

```text
nested podman ok
```

Run it twice when validating adoption. The nested engine storage is reusable,
and every inner smoke-test container should still be removed.

## Design details

### Namespace composition

The outer container explicitly uses:

```text
--userns=keep-id:uid=1000,gid=1001
```

Rootless host Podman first represents the invoking host user and group as parent
ID `0`. The explicit mapping then maps that identity to the fixed outer UID
`1000` and GID `1001`. With the minimum accepted subordinate ranges, the
container-visible outer maps have this composition regardless of the physical
host UID, GID, or subordinate-range starts:

```text
UID: outer 0..999 -> parent 1..1000
UID: outer 1000   -> invoking host user (parent 0)
UID: outer 1001..65536 -> parent 1001..65536

GID: outer 0..1000 -> parent 1..1001
GID: outer 1001    -> invoking host primary group (parent 0)
GID: outer 1002..65536 -> parent 1002..65536
```

The inner `/etc/subuid` and `/etc/subgid` ranges therefore split around the
outer development user's IDs:

```text
nonroot:1:999
nonroot:1001:64536

nonroot:1:1000
nonroot:1002:64535
```

These are IDs visible in the **outer** namespace. They are not physical host
subordinate IDs. At runtime, the test derives the two usable ranges on either
side of the fixed user, verifies that every target is present in the observed
outer maps, and validates the nested maps composed from them. Never copy a host
range start into the image: Linux requires every child mapping target to be
mapped by its immediate parent namespace.

`newuidmap` and `newgidmap` depend on set-user-ID behavior. Applying
`no-new-privileges` to the outer container prevents those helpers from doing
their job. Omitting that security option is narrow and does not justify
privileged mode or extra capabilities.

### Storage, cgroups, networking, and UTS

The nested engine uses `vfs`. This was the least-privilege working option and
avoids passing `/dev/fuse` into the outer container. VFS is slower and consumes
more space than overlay storage.

The inner smoke-test container uses:

```text
--network=none
--cgroups=disabled
--uts=host
```

Here, `--uts=host` means the inner container shares the **outer container's
private UTS namespace**, not the host machine's UTS namespace. Without this
setting, the nested `crun` failed at startup with:

```text
sethostname: Operation not permitted
```

Sharing the already isolated outer UTS namespace fixed the failure without
adding a hostname-related capability.

### Images and package sources

Both Hummingbird images are pinned to `linux/amd64` child-manifest digests.
Multi-platform index digests are not architecture-specific, so do not choose a
child digest by list order. Re-query the live Hummingbird catalog and verify the
registry manifest's platform mapping before updating either digest.

The Hummingbird package repository is preferred. Before enabling Fedora 43,
the build verifies that every Fedora-supplied package in the observed closure
is absent from Hummingbird. It then installs pinned direct Hummingbird inputs,
records installed-package provenance, removes the temporary Fedora repository,
cleans DNF metadata, and fails if temporary state remains.

**Warning:** this example preserves the tested prototype's `gpgcheck=0` setting
for the temporary Fedora repository. Before production use, install and trust
the Fedora 43 signing key, enable `gpgcheck=1`, and verify the full build again.

## Troubleshooting and adaptation

### `overlay is not supported over overlayfs`

Nested Podman initially selected overlay storage despite the system
`storage.conf`. The working setup copies `storage.conf` into the non-root user's
configuration and explicitly sets `CONTAINERS_STORAGE_CONF`. Confirm that
`podman info` reports `graphDriverName: vfs`; do not add `/dev/fuse` unless a
reviewed use case justifies that extra device.

### `newuidmap` or `newgidmap` fails

Check all of the following without changing the host from this example:

- host Podman reports `rootless: true`;
- the host user has exactly one contiguous subordinate UID and GID range and
  each contains at least 65,536 IDs;
- the outer `/proc/self/uid_map` and `/proc/self/gid_map` match the ranges used
  by `/etc/subuid` and `/etc/subgid` inside the image;
- the mapping-helper executables retain their package-provided set-user-ID
  permissions; and
- the outer launch does not apply `no-new-privileges`.

Do not repair host subordinate IDs from this example. Stop and ask the host
owner to make any account-level change.

### The workspace is not writable

Confirm that the workspace is owned by the invoking host user and that resolved
outer launch arguments retain the explicit fixed-ID `keep-id` option. Do not
enable `updateRemoteUserUID`: changing passwd identities does not rederive
nested subordinate maps or image-owned directory permissions.

### The subordinate-ID preflight rejects the host

The supported layout is deliberately narrow: one matching entry in `/etc/subuid`
and one in `/etc/subgid`, each with at least 65,536 IDs. Multiple matching
entries are treated as fragmented even when their total is large enough. An
undersized, fragmented, missing, malformed, or externally managed layout stops
before launch and suggests asking the host owner for help.

Do not create an account, edit `/etc/subuid` or `/etc/subgid`, request privilege
escalation, or weaken container isolation to make this example pass. Use an
already authorized host with the supported layout, or ask the host owner to
review the policy outside this workflow.

### The package build starts failing

Hummingbird's package repository is live even though the base image digest is
immutable. A package may be added, removed, or superseded, causing the explicit
gap check or pinned transaction to fail. Re-query Hummingbird and Fedora 43,
review the complete solver transaction, update the recorded gap list and pins,
and run the end-to-end test twice. Do not silently add another repository or
use `--skip-broken`.

### Dev Container launch details look surprising

Dev Container CLI `0.88.0` added its own `--userns=keep-id` and
`--security-opt label=disable` arguments when invoking Podman. The explicit
fixed-ID `keep-id` argument remained necessary for the tested mapping. This is
CLI-version-specific behavior; inspect the resolved launch whenever upgrading
the CLI.

### Evidence contains local information

Evidence is intentionally excluded by `.gitignore` and is not included in this
example. A run records host identities, kernel details, local paths, container
IDs, and image identities. Review and redact those files before sharing or
promoting them outside your environment.

The outer Dev Container remains available for reuse after the smoke test. If it
must be removed, use the exact container ID returned by `devcontainer up`,
inspect it first, and remove only that container. Never use a broad Podman reset
or prune command for this example.

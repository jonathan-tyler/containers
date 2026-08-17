# Nested Rootless Podman UID Comparison

Compares a fixed-host-identity baseline with a host-UID-independent variant.

## Variants

- `static-uid/` is the unchanged accepted baseline. It requires host UID `1000`,
  primary GID `1001`, and subordinate ranges starting at `100000`.
- `dynamic-uid/` maps a variable non-root host identity to the same fixed outer
  development user at container UID `1000` and GID `1001`, installs the Dev
  Container CLI in that outer container, and uses it with nested Podman to build
  and run an inner runtime-echo Dev Container. “Dynamic” describes the host
  identity; the container-side identity does not change.

Run either variant from its own directory:

```sh
cd <sub-dir>
just test-podman
```

Both commands emit exactly `nested podman ok` followed by one newline when the
host meets that variant's documented prerequisites. Runtime evidence remains
inside the selected variant's ignored `.devcontainer/evidence/` directory.

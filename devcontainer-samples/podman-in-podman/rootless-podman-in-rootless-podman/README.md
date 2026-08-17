# Nested Rootless Podman UID Comparison

Compares fixed and dynamic host-identity variants and demonstrates a nested Dev
Container CLI on the dynamic mapping.

## Variants

- `static-uid/` is the unchanged accepted baseline. It requires host UID `1000`,
  primary GID `1001`, and subordinate ranges starting at `100000`.
- `dynamic-uid/` maps a variable non-root host identity to the same fixed outer
  development user at container UID `1000` and GID `1001`. “Dynamic” describes
  the host identity; the container-side identity does not change.
- `devcontainer-cli/` preserves the dynamic-UID mapping and installs the Dev
  Container CLI in the outer container. That CLI uses nested Podman to build
  and run an inner runtime-echo Dev Container from `devcontainer.json`.

Run any variant from its own directory:

```sh
cd <sub-dir>
just test-podman
```

Each command emits exactly `nested podman ok` followed by one newline when the
host meets that variant's documented prerequisites. Runtime evidence remains
inside the selected variant's ignored `.devcontainer/evidence/` directory.

# Agent Instructions

- Pin every GitHub Actions `uses:` entry to a full commit SHA.
  - Keep a version comment immediately above each pinned action in the form `# owner/repo@vX.Y.Z`.
  - Do not delete those comments unless the corresponding action step is removed.
- When referencing devcontainer features published by this repo, use their published `ghcr.io/jonathan-tyler/containers/<feature>:0` URL in `features`, `overrideFeatureInstallOrder`, lockfiles, and docs. Do not use local relative paths or bare feature IDs for published features.
- `homebrew-packages-additional` is a generated publish alias for `homebrew-packages`. Edit the primary feature only; `just prepare` and `just publish-check` mirror it into the scratch packaging tree.
- Prefer `Containerfile` over `Dockerfile` for container build fixtures and image definitions when the calling tool accepts either name and the change does not break existing references. When switching, update explicit `dockerfile` references alongside the rename.
- For development, prefer a named passwd user such as `nonroot`; if no suitable named user exists, use `root` instead of `65532`. Many applications do not work correctly with nameless UID users.
- Red Hat hardened images commonly run as UID `65532` with `HOME=/tmp` and no `/home/<user>` directory. The image may not ship a stable passwd entry for that UID, and Podman may synthesize one at runtime, so tests and features should assert stable runtime behavior like UID, `HOME`, and missing `/home` state instead of relying on passwd database details.

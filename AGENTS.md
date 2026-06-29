# Agent Instructions

- Pin every GitHub Actions `uses:` entry to a full commit SHA.
  - Keep a version comment immediately above each pinned action in the form `# owner/repo@vX.Y.Z`.
  - Do not delete those comments unless the corresponding action step is removed.
- For feature installers, prefer package repositories that are already enabled in the base image. On Red Hat hardened images, try `public-hummingbird-x86_64-rpms` first when it is present. If that repo cannot satisfy the required dependency graph, prefer the image's existing `dnf` configuration next. Only add temporary repo files as a last resort, and remove them from the final image.
- Red Hat hardened images commonly run as UID `65532` with `HOME=/tmp` and no `/home/<user>` directory. The image may not ship a stable passwd entry for that UID, and Podman may synthesize one at runtime, so tests and features should assert stable runtime behavior like UID, `HOME`, and missing `/home` state instead of relying on passwd database details.
- Prefer `Containerfile` over `Dockerfile` for container build fixtures and image definitions when the calling tool accepts either name and the change does not break existing references. When switching, update explicit `dockerfile` references alongside the rename.

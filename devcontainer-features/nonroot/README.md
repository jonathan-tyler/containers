# Non-Root User (`nonroot`)

Create a named non-root passwd user for images that only provide `root` or a numeric runtime UID.

## Example Usage

```json
"features": {
  "ghcr.io/jonathan-tyler/containers/nonroot:0": {
    "username": "nonroot"
  }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| username | Username to create when it does not already exist. | string | nonroot |
| user_uid | Optional numeric UID for the created user. Leave as automatic to let the system choose. | string | automatic |
| user_gid | Optional numeric GID for the created user's primary group. Leave as automatic to let the system choose. | string | automatic |
| user_home | Home directory for the created user. Leave as automatic to use /home/<username>. | string | automatic |
| user_shell | Login shell for the created user. Leave as automatic to prefer /bin/bash when present and fall back to /bin/sh. | string | automatic |

## Notes

- The feature only creates the user and primary group; it does not change the container's runtime user.
- Use this when another feature, such as `homebrew-packages`, needs a real named non-root passwd user.
- If the requested user already exists as a non-root account, the feature leaves it unchanged.

## OS Support

This feature targets Linux containers and supports Ubuntu/Debian, RHEL-family images, and Alpine.

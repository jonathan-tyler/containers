# Chezmoi (`chezmoi`)

Install chezmoi for managing dotfiles in dev containers.

## Example Usage

```json
"features": {
  "ghcr.io/jonathan-tyler/containers/chezmoi:0": {}
}
```

## Notes

- This feature installs the `chezmoi` package from the image's `dnf` repositories.
- Pair it with your dotfiles repository and a startup hook if you want automatic apply behavior.

## OS Support

This feature currently targets Fedora and RHEL-family images with `dnf`.

## Reference

- https://www.chezmoi.io/

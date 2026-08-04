# yt-dlp

This Hummingbird-based container runs [yt-dlp](https://github.com/yt-dlp/yt-dlp). Arguments supplied after the image name are passed directly to `yt-dlp`.

- Image: `ghcr.io/jonathan-tyler/containers/yt-dlp:latest`
- Runtime: Red Hat Hummingbird Python 3.14
- Runtime user: UID `65532`
- Working directory: `/downloads`

The image does not include FFmpeg, so formats that require merging or post-processing are unavailable.

## Usage

### Downloading a Video

Mount a writable output directory and pass a URL to the container:

```console
podman run --rm --userns=keep-id:uid=65532,gid=65532 \
  --volume "${PWD}:/downloads:z" \
  ghcr.io/jonathan-tyler/containers/yt-dlp:latest \
  'https://www.youtube.com/watch?v=VIDEO_ID'
```

The user namespace maps the container's UID `65532` to your host user so downloaded files are writable without changing the host directory's ownership.

### Passing yt-dlp Options

Options are passed directly to `yt-dlp`. For example, list the formats available for a URL:

```console
podman run --rm --userns=keep-id:uid=65532,gid=65532 \
  --volume "${PWD}:/downloads:z" \
  ghcr.io/jonathan-tyler/containers/yt-dlp:latest \
  --list-formats 'https://www.youtube.com/watch?v=VIDEO_ID'
```

### Defining a zsh Function

Add the following function to `.zshrc` to use the container like a locally installed utility. Change the `output_dir` assignment to set a different default output directory.

```zsh
yt-dlp() {
  local output_dir="${HOME}/Downloads"

  mkdir -p "${output_dir}" || return
  podman run --rm --interactive \
    --userns=keep-id:uid=65532,gid=65532 \
    --volume "${output_dir}:/downloads:z" \
    ghcr.io/jonathan-tyler/containers/yt-dlp:latest "$@"
}
```

When you execute `yt-dlp` with options or URLs, the function passes them to the container and writes output to `output_dir`.

## Building Locally

Build the image and run the lightweight `--version` check without downloading media:

```console
just test-yt-dlp
```

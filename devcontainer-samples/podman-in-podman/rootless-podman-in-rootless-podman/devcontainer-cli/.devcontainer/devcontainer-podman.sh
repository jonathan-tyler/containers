#!/usr/bin/env bash
set -euo pipefail

readonly podman='/usr/bin/podman'

prefix_local_image_names() {
  local argument
  local skip_value=0
  local -a rewritten=()

  for argument in "$@"; do
    if (( skip_value )); then
      rewritten+=("${argument}")
      skip_value=0
      continue
    fi

    case "${argument}" in
      --name|--label|--env|-e|--mount|--volume|-v|--entrypoint|--user|-u|--workdir|-w)
        rewritten+=("${argument}")
        skip_value=1
        ;;
      vsc-*)
        rewritten+=("localhost/${argument}")
        ;;
      *)
        rewritten+=("${argument}")
        ;;
    esac
  done

  printf '%s\0' "${rewritten[@]}"
}

if [[ "${1-}" == buildx && "${2-}" == build ]]; then
  exec "${podman}" "$@"
fi

case "${1-}" in
  inspect)
    if [[ " $* " == *' --type image '* ]]; then
      mapfile -d '' -t arguments < <(prefix_local_image_names "$@")
      exec "${podman}" "${arguments[@]}"
    fi
    ;;
  image)
    if [[ "${2-}" == inspect ]]; then
      mapfile -d '' -t arguments < <(prefix_local_image_names "$@")
      exec "${podman}" "${arguments[@]}"
    fi
    ;;
esac

exec "${podman}" "$@"

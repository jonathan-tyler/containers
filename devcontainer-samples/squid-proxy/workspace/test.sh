#!/usr/bin/env bash
set -euo pipefail

for i in $(seq 1 30); do
  if curl -fsS --output /dev/null http://example.com/; then
    break
  fi

  if [ "$i" -eq 30 ]; then
    printf 'example.com did not become reachable through squid\n' >&2
    exit 1
  fi

  sleep 1
done

curl -fsS --output /dev/null http://example.net/ && {
  printf 'example.net should have failed through squid\n' >&2
  exit 1
}

curl -fsS --output /dev/null http://example.com/

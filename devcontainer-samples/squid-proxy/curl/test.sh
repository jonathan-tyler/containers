#!/usr/bin/env bash
set -euo pipefail

if curl -fsS --output /dev/null http://example.net/; then
  printf 'example.net should have failed through squid\n' >&2
  exit 1
fi

curl -fsS --output /dev/null http://example.com/

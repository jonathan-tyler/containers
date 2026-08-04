#!/usr/bin/env bash

set -euo pipefail

if [ "${1:-}" = "events" ]; then
    shift
    podman events "$@" | jq --unbuffered --compact-output '{
        status: (.Status // .status),
        id: (.ID // .id),
        Type: (.Type // .type),
        Action: (.Status // .Action // .status),
        Actor: {
            ID: (.ID // .id),
            Attributes: (.Attributes // {})
        },
        time: .time,
        timeNano: .timeNano
    }'
else
    exec podman "$@"
fi

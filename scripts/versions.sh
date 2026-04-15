#!/usr/bin/env zsh
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <version-prefix>" >&2
    exit 1
fi

DATA_DIR="${0:a:h}/data"

if [[ ! -f "$DATA_DIR/game.json" ]]; then
    echo "Data directory not found. Run fetch-data.sh first." >&2
    exit 1
fi

PREFIX="$1"

result=$(jq -r --arg p "${PREFIX}." '[.[] | select(.version == $p[:-1] or (.version | startswith($p)))] | .[] | .version' "$DATA_DIR/game.json")

if [[ -z "$result" ]]; then
    echo "Error: No versions found matching '$PREFIX'. Try running fetch-data.sh to update." >&2
    exit 1
fi

echo "$result"

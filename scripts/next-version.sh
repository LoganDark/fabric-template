#!/usr/bin/env zsh
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <game-version> [bookmark]" >&2
    exit 1
fi

GAME_VERSION="$1"
BOOKMARK="${2:-$GAME_VERSION}"
SCRIPT_DIR="${0:a:h}"
ROOT_DIR="${SCRIPT_DIR:h}"

cd "$ROOT_DIR"

jj new -A @ -m "$GAME_VERSION"
jj b c "$BOOKMARK"
./scripts/set-version.sh "$GAME_VERSION"

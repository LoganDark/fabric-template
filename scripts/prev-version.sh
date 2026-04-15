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

# Save current revision's change ID and commit ID
changeid=$(jj log -r '@' --no-graph -T 'change_id')
commitid=$(jj log -r '@' --no-graph -T 'commit_id')

# Insert new revision before current
jj new -B @ -m "$GAME_VERSION"
jj b c "$BOOKMARK"
jj restore --from "$commitid"
./scripts/set-version.sh "$GAME_VERSION"

# Restore the original revision from its old commit ID
jj restore --from "$commitid" --to "$changeid"

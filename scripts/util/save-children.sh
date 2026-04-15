#!/usr/bin/env zsh
# Outputs change_id\tcommit_id pairs for children of a revision.
# Usage: save-children.sh <rev> [revset_filter]
set -euo pipefail

REV="$1"
FILTER="${2:-}"

if [[ -n "$FILTER" ]]; then
    REVSET="(children($REV)) & ($FILTER)"
else
    REVSET="children($REV)"
fi

jj log -r "$REVSET" --no-graph -T 'change_id ++ "\t" ++ commit_id ++ "\n"'

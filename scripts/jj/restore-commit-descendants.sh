#!/usr/bin/env zsh
# Restores descendants of a revision from an old commit ID.
# Usage: restore-commit-descendants.sh <commit> [revision]
set -euo pipefail

SCRIPTS_DIR="${0:a:h:h}"
REPO_DIR="${SCRIPTS_DIR:h}"

if [[ $# -lt 1 || $# -gt 2 ]]; then
	echo "Usage: $0 <commit> [revision]" >&2
	exit 1
fi

BASE_COMMIT="$1"
REV=$("$SCRIPTS_DIR/jj/get-change.sh" "${2:-@}")

for CHILD_CHANGE in $(jj -R "$REPO_DIR" --quiet log -r "children($REV)" --no-graph -T 'change_id ++ "\n"'); do
	jj -R "$REPO_DIR" new -B "$CHILD_CHANGE" --no-edit
	SQUASH_CHANGE=$(jj -R "$REPO_DIR" --quiet show -r "$CHILD_CHANGE"- --no-patch -T commit_id)
	jj -R "$REPO_DIR" restore -f "$BASE_COMMIT" -t "$SQUASH_CHANGE"
	jj -R "$REPO_DIR" squash -f "$SQUASH_CHANGE" -t "$CHILD_CHANGE"
done

#!/usr/bin/env zsh
# Outputs the commit ID of a revision.
# Usage: get-commit.sh [revision]
set -euo pipefail

SCRIPTS_DIR="${0:a:h:h}"
REPO_DIR="${SCRIPTS_DIR:h}"

if [[ $# -gt 1 ]]; then
	echo "Usage: $0 [revision]" >&2
	exit 1
fi

REV="${1:-@}"

jj -R "$REPO_DIR" --quiet show -r "$REV" --no-patch -T commit_id

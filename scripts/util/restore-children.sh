#!/usr/bin/env zsh
# Restores children from saved change_id\tcommit_id pairs (as produced by save-children.sh).
# Usage: restore-children.sh <<< "$saved"
set -euo pipefail

while IFS=$'\t' read -r cid ccid; do
    [[ -z "$cid" ]] && continue
    jj restore --from "$ccid" --to "$cid" 2>/dev/null
done

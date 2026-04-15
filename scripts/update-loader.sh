#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="${0:a:h}"
DATA_DIR="$SCRIPT_DIR/data"
ROOT_DIR="${SCRIPT_DIR:h}"

if [[ ! -f "$DATA_DIR/loader.json" ]]; then
    echo "Error: loader.json not found. Run fetch-data.sh first." >&2
    exit 1
fi

loader_version=$(jq -r '[.[] | select(.stable)] | .[0].version' "$DATA_DIR/loader.json")

if [[ -z "$loader_version" || "$loader_version" == "null" ]]; then
    echo "Error: No stable loader version found. Try running fetch-data.sh to update." >&2
    exit 1
fi

echo "Latest stable loader: $loader_version"

# Save current working copy revision
original=$(jj log -r '@' --no-graph -T 'change_id')

update_tree() {
    local rev="$1"
    local depth="${2:-0}"
    local indent=$(printf '%*s' $((depth * 2)) '')

    # Edit this revision and check if update is needed
    jj edit "$rev" 2>/dev/null
    local old_loader=$(grep '^loader_version=' "$ROOT_DIR/gradle.properties" | cut -d= -f2)

    if [[ "$old_loader" == "$loader_version" ]]; then
        echo "${indent}Skipped $rev (already $loader_version)"
    else
        # Save children before we modify this rev
        local saved=$("$SCRIPT_DIR/util/save-children.sh" "$rev")

        gsed -i "s/^loader_version=.*/loader_version=$loader_version/" "$ROOT_DIR/gradle.properties"
        echo "${indent}Updated $rev (from $old_loader to $loader_version)"

        # Restore children from their old commit IDs
        "$SCRIPT_DIR/util/restore-children.sh" <<< "$saved"
    fi

    # Recurse into each child (use jj to get current children, not saved)
    while IFS=$'\t' read -r cid ccid; do
        [[ -z "$cid" ]] && continue
        update_tree "$cid" $((depth + 1))
    done < <("$SCRIPT_DIR/util/save-children.sh" "$rev")
}

update_tree mapped

# Restore original working copy
jj edit "$original" 2>/dev/null

echo "Done. Loader version updated to $loader_version across all revisions from common."

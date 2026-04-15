#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="${0:a:h}"
DATA_DIR="$SCRIPT_DIR/data"
ROOT_DIR="${SCRIPT_DIR:h}"

if [[ ! -f "$DATA_DIR/yarn.json" ]]; then
    echo "Error: yarn.json not found. Run fetch-data.sh first." >&2
    exit 1
fi

if [[ ! -f "$DATA_DIR/game.json" ]]; then
    echo "Error: game.json not found. Run fetch-data.sh first." >&2
    exit 1
fi

FILTER="~ unmapped ~ descendants(unmapped)"

# Save current working copy revision
original=$(jj log -r '@' --no-graph -T 'change_id')

update_tree() {
    local rev="$1"
    local depth="${2:-0}"
    local indent=$(printf '%*s' $((depth * 2)) '')

    # Edit this revision and read its game version
    jj edit "$rev" 2>/dev/null
    local game_version=$(grep '^minecraft_version=' "$ROOT_DIR/gradle.properties" | cut -d= -f2)
    local old_yarn=$(grep '^yarn_mappings=' "$ROOT_DIR/gradle.properties" | cut -d= -f2)

    # Look up latest yarn for this game version
    local yarn=$(jq -r --arg gv "$game_version" \
        '[.[] | select(.gameVersion == $gv)] | .[0].version // empty' \
        "$DATA_DIR/yarn.json")

    echo "${indent}Latest yarn for $game_version is ${yarn:-<none>}"

    if [[ -z "$yarn" ]]; then
        echo "${indent}Skipped $rev ($game_version, no yarn available)"
    elif [[ "$old_yarn" == "$yarn" ]]; then
        echo "${indent}Skipped $rev (already $yarn)"
    else
        # Save children before we modify this rev
        local saved=$("$SCRIPT_DIR/util/save-children.sh" "$rev" "$FILTER")

        gsed -i "s/^yarn_mappings=.*/yarn_mappings=$yarn/" "$ROOT_DIR/gradle.properties"
        echo "${indent}Updated $rev (from $old_yarn to $yarn)"

        # Restore children from their old commit IDs
        "$SCRIPT_DIR/util/restore-children.sh" <<< "$saved"
    fi

    # Recurse into each child (use jj to get current children, not saved)
    while IFS=$'\t' read -r cid ccid; do
        [[ -z "$cid" ]] && continue
        update_tree "$cid" $((depth + 1))
    done < <("$SCRIPT_DIR/util/save-children.sh" "$rev" "$FILTER")
}

# Start from children of mapped, excluding unmapped and its descendants
saved=$("$SCRIPT_DIR/util/save-children.sh" "mapped" "$FILTER")
while IFS=$'\t' read -r cid ccid; do
    [[ -z "$cid" ]] && continue
    update_tree "$cid"
done <<< "$saved"

# Restore original working copy
jj edit "$original" 2>/dev/null

echo "Done. Yarn mappings updated across all revisions between mapped and unmapped."

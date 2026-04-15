#!/usr/bin/env zsh
set -euo pipefail

SCRIPTS_DIR="${0:a:h:h}"
DATA_DIR="$SCRIPTS_DIR/data"
REPO_DIR="${SCRIPTS_DIR:h}"

loader_version=$(zsh "$SCRIPTS_DIR/template/properties.sh" | grep '^loader_version=' | cut -d= -f2)

if [[ -z "$loader_version" ]]; then
    echo "Error: Could not determine loader version." >&2
    exit 1
fi

echo "Latest stable loader: $loader_version"

# Save current working copy revision
original=$(jj -R "$REPO_DIR" log -r '@' --no-graph -T 'change_id')

update_tree() {
    local rev="$1"
    local depth="${2:-0}"
    local indent=$(printf '%*s' $((depth * 2)) '')

    # Edit this revision and check if update is needed
    jj -R "$REPO_DIR" edit "$rev" 2>/dev/null
    local old_loader=$(grep '^loader_version=' "$REPO_DIR/gradle.properties" | cut -d= -f2)

    if [[ "$old_loader" == "$loader_version" ]]; then
        echo "${indent}Skipped $rev (already $loader_version)"
    else
        local commit=$("$SCRIPTS_DIR/jj/get-commit.sh")
        gsed -i "s/^loader_version=.*/loader_version=$loader_version/" "$REPO_DIR/gradle.properties"
        echo "${indent}Updated $rev (from $old_loader to $loader_version)"
        "$SCRIPTS_DIR/jj/restore-commit-descendants.sh" "$commit"
    fi

    # Recurse into each child
    for cid in $(jj -R "$REPO_DIR" --quiet log -r "children($rev)" --no-graph -T 'change_id ++ "\n"'); do
        [[ -z "$cid" ]] && continue
        update_tree "$cid" $((depth + 1))
    done
}

update_tree mapped

# Restore original working copy
jj -R "$REPO_DIR" edit "$original" 2>/dev/null

echo "Done. Loader version updated to $loader_version across all revisions from common."

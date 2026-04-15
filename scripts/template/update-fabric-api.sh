#!/usr/bin/env zsh
set -euo pipefail

SCRIPTS_DIR="${0:a:h:h}"
DATA_DIR="$SCRIPTS_DIR/data"
REPO_DIR="${SCRIPTS_DIR:h}"

# Save current working copy revision
original=$(jj -R "$REPO_DIR" log -r '@' --no-graph -T 'change_id')

update_tree() {
	local rev="$1"
	local depth="${2:-0}"
	local indent=$(printf '%*s' $((depth * 2)) '')

	# Create an empty child of rev so any modifications can be squashed back
	# into it without rewriting its descendants' diffs.
	jj -R "$REPO_DIR" new "$rev" 2>/dev/null
	local game_version=$(grep '^minecraft_version=' "$REPO_DIR/gradle.properties" | cut -d= -f2)
	local old_api=$(grep '^fabric_api_version=' "$REPO_DIR/gradle.properties" | cut -d= -f2)

	# Look up latest fabric API for this game version
	local api=$(zsh "$SCRIPTS_DIR/template/properties.sh" "$game_version" | grep '^fabric_api_version=' | cut -d= -f2)

	if [[ -z "$api" ]]; then
		echo "${indent}Skipped $rev ($game_version, no Fabric API available)"
	elif [[ "$old_api" == "$api" ]]; then
		echo "${indent}Skipped $rev (already $api)"
	else
		gsed -i "s/^fabric_api_version=.*/fabric_api_version=$api/" "$REPO_DIR/gradle.properties"
		echo "${indent}Updated $rev (from ${old_api:-<empty>} to $api)"
		jj -R "$REPO_DIR" squash --restore-descendants 2>/dev/null
	fi

	# Recurse into each child of rev. The next jj new (or the final jj edit
	# below) will move @ away, auto-cleaning the empty undescribed leftover.
	for cid in $(jj -R "$REPO_DIR" --quiet log -r "children($rev)" --no-graph -T 'change_id ++ "\n"'); do
		[[ -z "$cid" ]] && continue
		update_tree "$cid" $((depth + 1))
	done
}

update_tree mapped

# Restore original working copy
jj -R "$REPO_DIR" edit "$original" 2>/dev/null

echo "Done. Fabric API version updated across all revisions from mapped."

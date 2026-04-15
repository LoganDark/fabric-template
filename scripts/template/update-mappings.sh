#!/usr/bin/env zsh
set -euo pipefail

SCRIPTS_DIR="${0:a:h:h}"
DATA_DIR="$SCRIPTS_DIR/data"
REPO_DIR="${SCRIPTS_DIR:h}"

FILTER="~ unmapped ~ descendants(unmapped)"

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
	local old_yarn=$(grep '^yarn_mappings=' "$REPO_DIR/gradle.properties" | cut -d= -f2)

	# Look up latest yarn for this game version
	local yarn=$(zsh "$SCRIPTS_DIR/template/properties.sh" "$game_version" | grep '^yarn_mappings=' | cut -d= -f2)

	echo "${indent}Latest yarn for $game_version is ${yarn:-<none>}"

	if [[ -z "$yarn" ]]; then
		echo "${indent}Skipped $rev ($game_version, no yarn available)"
	elif [[ "$old_yarn" == "$yarn" ]]; then
		echo "${indent}Skipped $rev (already $yarn)"
	else
		gsed -i "s/^yarn_mappings=.*/yarn_mappings=$yarn/" "$REPO_DIR/gradle.properties"
		echo "${indent}Updated $rev (from $old_yarn to $yarn)"
		jj -R "$REPO_DIR" squash --restore-descendants 2>/dev/null
	fi

	# Recurse into each child of rev, excluding unmapped and its descendants.
	# The next jj new (or the final jj edit below) will move @ away,
	# auto-cleaning the empty undescribed leftover.
	for cid in $(jj -R "$REPO_DIR" --quiet log -r "children($rev) & ($FILTER)" --no-graph -T 'change_id ++ "\n"'); do
		[[ -z "$cid" ]] && continue
		update_tree "$cid" $((depth + 1))
	done
}

# Start from children of mapped, excluding unmapped and its descendants
for cid in $(jj -R "$REPO_DIR" --quiet log -r "children(mapped) & ($FILTER)" --no-graph -T 'change_id ++ "\n"'); do
	[[ -z "$cid" ]] && continue
	update_tree "$cid"
done

# Restore original working copy
jj -R "$REPO_DIR" edit "$original" 2>/dev/null

echo "Done. Yarn mappings updated across all revisions between mapped and unmapped."

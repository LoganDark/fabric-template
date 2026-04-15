#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="${0:a:h}"
ROOT_DIR="${SCRIPT_DIR:h}"

# Save commit IDs of direct children before we modify @
saved=$("$SCRIPT_DIR/util/save-children.sh" '@')

# Launch the game
"$ROOT_DIR/gradlew" -p "$ROOT_DIR" runClient

# Show what changed
echo ""
echo "Changes to options.txt:"
jj diff run/options.txt

# Offer to edit the file before restoring children
echo -n "Open run/options.txt in nano? [y/N] "
read -r answer
if [[ "$answer" == [yY] ]]; then
    nano "$ROOT_DIR/run/options.txt"
fi

# Restore children from their old commit IDs
"$SCRIPT_DIR/util/restore-children.sh" <<< "$saved"

echo "Done. Children restored."

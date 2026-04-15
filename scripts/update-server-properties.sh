#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="${0:a:h}"
ROOT_DIR="${SCRIPT_DIR:h}"

# Save commit IDs of direct children before we modify @
saved=$("$SCRIPT_DIR/util/save-children.sh" '@')

# Launch the server
"$ROOT_DIR/gradlew" -p "$ROOT_DIR" runServer

# Show what changed
echo ""
echo "Changes to server.properties:"
jj diff run/server.properties

# Offer to edit the file before restoring children
echo -n "Open run/server.properties in nano? [y/N] "
read -r answer
if [[ "$answer" == [yY] ]]; then
    nano "$ROOT_DIR/run/server.properties"
fi

# Restore children from their old commit IDs
"$SCRIPT_DIR/util/restore-children.sh" <<< "$saved"

echo "Done. Children restored."

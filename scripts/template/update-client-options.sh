#!/usr/bin/env zsh
set -euo pipefail

SCRIPTS_DIR="${0:a:h:h}"
DATA_DIR="$SCRIPTS_DIR/data"
REPO_DIR="${SCRIPTS_DIR:h}"

# Save commit before we modify @
commit=$("$SCRIPTS_DIR/jj/get-commit.sh")

# Launch the game
"$REPO_DIR/gradlew" -p "$REPO_DIR" runClient

# Show what changed
echo ""
echo "Changes to options.txt:"
jj -R "$REPO_DIR" diff run/options.txt

# Offer to edit the file before restoring descendants
echo -n "Open run/options.txt in nano? [y/N] "
read -r answer
if [[ "$answer" == [yY] ]]; then
    nano "$REPO_DIR/run/options.txt"
fi

# Restore descendants from their old commit
"$SCRIPTS_DIR/jj/restore-commit-descendants.sh" "$commit"

echo "Done. Descendants restored."

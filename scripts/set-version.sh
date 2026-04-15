#!/usr/bin/env zsh
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <game-version>" >&2
    exit 1
fi

GAME_VERSION="$1"
SCRIPT_DIR="${0:a:h}"
ROOT_DIR="${SCRIPT_DIR:h}"

if [[ ! -f "$ROOT_DIR/gradle.properties" ]]; then
    echo "Error: gradle.properties not found in $ROOT_DIR" >&2
    exit 1
fi

if [[ ! -f "$ROOT_DIR/src/main/resources/fabric.mod.json" ]]; then
    echo "Error: fabric.mod.json not found in $ROOT_DIR" >&2
    exit 1
fi

# Get properties for this version
props=$("$SCRIPT_DIR/properties.sh" "$GAME_VERSION")

# Update gradle.properties
while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    gsed -i "s|^${key}=.*|${key}=${value}|" "$ROOT_DIR/gradle.properties"
done <<< "$props"

# Fabric Loader normalizes "snapshot" to "alpha" in version strings
# e.g. 26.2-snapshot-3 -> 26.2-alpha.3
MOD_VERSION=$(echo "$GAME_VERSION" | gsed 's/\-snapshot-/-alpha./')

# Update fabric.mod.json minecraft dependency to normalized version
gsed -i "s|\"minecraft\": \".*\"|\"minecraft\": \"${MOD_VERSION}\"|" \
    "$ROOT_DIR/src/main/resources/fabric.mod.json"

echo "Updated to Minecraft $GAME_VERSION:"
echo "$props"
echo ""

# Run ideaSyncTask
echo "Running ideaSyncTask..."
"$ROOT_DIR/gradlew" -p "$ROOT_DIR" ideaSyncTask

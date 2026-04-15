#!/usr/bin/env zsh
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <game-version>" >&2
    exit 1
fi

GAME_VERSION="$1"
DATA_DIR="${0:a:h}/data"

for f in game.json loader.json yarn.json fabric-loom-maven.xml fabric-api-maven.xml; do
    if [[ ! -f "$DATA_DIR/$f" ]]; then
        echo "Error: $f not found. Run fetch-data.sh first." >&2
        exit 1
    fi
done

# Validate game version exists
if ! jq -e --arg gv "$GAME_VERSION" 'any(.[]; .version == $gv)' "$DATA_DIR/game.json" >/dev/null 2>&1; then
    echo "Error: Game version '$GAME_VERSION' not found. Try running fetch-data.sh to update." >&2
    exit 1
fi

# Loader: latest stable
loader_version=$(jq -r '[.[] | select(.stable)] | .[0].version' "$DATA_DIR/loader.json")

if [[ -z "$loader_version" || "$loader_version" == "null" ]]; then
    echo "Error: No stable loader version found. Try running fetch-data.sh to update." >&2
    exit 1
fi

# Yarn: latest build for this game version (omit if none, e.g. snapshots)
yarn_mappings=$(jq -r --arg gv "$GAME_VERSION" \
    '[.[] | select(.gameVersion == $gv)] | .[0].version // empty' \
    "$DATA_DIR/yarn.json")

# Loom: latest non-alpha version from maven metadata
loom_version=$(grep '<version>' "$DATA_DIR/fabric-loom-maven.xml" \
    | sed 's/.*<version>\(.*\)<\/version>.*/\1/' \
    | grep -v 'alpha' \
    | tail -1)

if [[ -z "$loom_version" ]]; then
    echo "Error: No loom version found. Try running fetch-data.sh to update." >&2
    exit 1
fi

# Fabric API: latest version matching the game version suffix
# For "26.2-snapshot-3" the suffix is "26.2", otherwise use full version
# Falls back to shorter prefixes (e.g. 1.17.1 -> 1.17) if no exact match
if [[ "$GAME_VERSION" == *-snapshot-* ]]; then
    api_suffix="${GAME_VERSION%%-snapshot-*}"
else
    api_suffix="$GAME_VERSION"
fi

all_api_versions=$(grep '<version>' "$DATA_DIR/fabric-api-maven.xml" \
    | sed 's/.*<version>\(.*\)<\/version>.*/\1/')

fabric_api_version=$(echo "$all_api_versions" | { grep "+${api_suffix}\$" || true; } | tail -1)
if [[ -z "$fabric_api_version" && "$api_suffix" == *.* ]]; then
    api_suffix="${api_suffix%.*}"
    fabric_api_version=$(echo "$all_api_versions" | { grep "+${api_suffix}\$" || true; } | tail -1)
fi

if [[ -z "$fabric_api_version" ]]; then
    echo "Error: No Fabric API version found for '$GAME_VERSION'. Try running fetch-data.sh to update." >&2
    exit 1
fi

# Output
echo "minecraft_version=$GAME_VERSION"
[[ -n "$yarn_mappings" ]] && echo "yarn_mappings=$yarn_mappings"
echo "loader_version=$loader_version"
echo "loom_version=$loom_version"
echo ""
echo "# Fabric API"
echo "fabric_api_version=$fabric_api_version"

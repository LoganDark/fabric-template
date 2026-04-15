#!/usr/bin/env zsh
set -euo pipefail

BASE_META="https://meta.fabricmc.net"
BASE_MAVEN="https://maven.fabricmc.net"
DATA_DIR="${0:a:h}/data"

mkdir -p "$DATA_DIR"

echo "Fetching installer versions..."
curl -sf "$BASE_META/v2/versions/installer" -o "$DATA_DIR/installer.json"

echo "Fetching game versions..."
curl -sf "$BASE_META/v2/versions/game" -o "$DATA_DIR/game.json"

echo "Fetching loader versions..."
curl -sf "$BASE_META/v2/versions/loader" -o "$DATA_DIR/loader.json"

echo "Fetching yarn versions..."
curl -sf "$BASE_META/v2/versions/yarn" -o "$DATA_DIR/yarn.json"

echo "Fetching JD list..."
curl -sf "$BASE_MAVEN/jdlist.txt" | jq -R -s 'split("\n") | map(select(. != ""))' > "$DATA_DIR/jdlist.json"

echo "Fetching fabric-api maven metadata..."
curl -sf "$BASE_MAVEN/net/fabricmc/fabric-api/fabric-api/maven-metadata.xml" -o "$DATA_DIR/fabric-api-maven.xml"

echo "Fetching fabric-loom maven metadata..."
curl -sf "$BASE_MAVEN/net/fabricmc/fabric-loom/maven-metadata.xml" -o "$DATA_DIR/fabric-loom-maven.xml"

echo "Done. Files written to $DATA_DIR/"

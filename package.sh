#!/usr/bin/env bash
# Build the release zip (Nexus Mods / GitHub): release/StellarBladePlayAs-<version>.zip, laid out like the game folder,
# so players extract it into StellarBlade/ and nothing else (UE4SS is a separate requirement, see the README).
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)
VERSION=$(sed -n 's/^local VERSION = "\(.*\)"$/\1/p' "$ROOT/Scripts/main.lua")
[[ -n $VERSION ]] || { echo "no VERSION in main.lua"; exit 1; }
grep -q "^## $VERSION\b" "$ROOT/CHANGELOG.md" || { echo "CHANGELOG.md has no '## $VERSION' section"; exit 1; }
# the README names the version in its intro and the zip's name: both this one (3.1.0 is UE4SS's)
OTHER=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$ROOT/README.md" | grep -vxF "$VERSION" | grep -vxF "3.1.0" | sort -u || true)
[[ -z $OTHER ]] || { echo "README.md names another version: $OTHER"; exit 1; }
# the sims must pass
"$ROOT/test/run.sh" >/dev/null || { echo "test/run.sh fails: not packaged"; exit 1; }

"$ROOT/build.sh" >/dev/null
STAGE=$ROOT/build/stage
OUT=$ROOT/release
mkdir -p "$OUT"
# (for players: the README's install block only, and the license)
rm -f "$STAGE/StellarBladePlayAs-README.md"
sed -n '/^<!-- install -->$/,/^<!-- \/install -->$/p' "$ROOT/README.md" | sed '1d;$d' > "$STAGE/StellarBladePlayAs-README.md"
[[ -s $STAGE/StellarBladePlayAs-README.md ]] || { echo "README.md has no <!-- install --> block"; exit 1; }
cp "$ROOT/LICENSE" "$STAGE/StellarBladePlayAs-LICENSE.txt"

ZIP=$OUT/StellarBladePlayAs-$VERSION.zip
rm -f "$ZIP"
(cd "$STAGE" && zip -qr -X "$ZIP" .)
ls -l "$ZIP"
(cd "$STAGE" && find . -type f | sort)

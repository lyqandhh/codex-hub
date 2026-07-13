#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
SOURCE="$ROOT/dist/Codex HUD.app"
TARGET="$HOME/Applications/Codex HUD.app"

"$ROOT/scripts/build-app.sh" >/dev/null
mkdir -p "$HOME/Applications"
pkill -x CodexHUD 2>/dev/null || true
rm -rf "$TARGET"
ditto "$SOURCE" "$TARGET"
open "$TARGET"

echo "$TARGET"

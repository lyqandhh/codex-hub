#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
APP="$ROOT/dist/Codex HUD.app"
CONTENTS="$APP/Contents"

cd "$ROOT"
swift build -c release

rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$ROOT/.build/release/CodexHUD" "$CONTENTS/MacOS/CodexHUD"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"
chmod 755 "$CONTENTS/MacOS/CodexHUD"
codesign --force --deep --sign - "$APP"

echo "$APP"

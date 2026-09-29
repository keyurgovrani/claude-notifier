#!/usr/bin/env bash
# Extracts the multi-resolution Claude icon from /Applications/Claude.app
# and packs it as Claude.icns (used as fallback when Claude desktop
# is absent on a teammate's machine).
#
# Re-run when Claude desktop updates and the icon family changes.
# Requires: macOS, /Applications/Claude.app installed, iconutil (ships with Xcode CLT).
#
# Uses iconutil to read Assets.car directly — avoids the sips PNG roundtrip
# that degrades colour profiles and drops high-res frames.

set -euo pipefail

APP_PATH="/Applications/Claude.app"
ASSETS_CAR="$APP_PATH/Contents/Resources/Assets.car"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$SCRIPT_DIR/Claude.icns"
ICONSET=$(mktemp -d -t claude-iconset)/claude.iconset

trap 'rm -rf "$(dirname "$ICONSET")"' EXIT

if [ ! -d "$APP_PATH" ]; then
  echo "error: $APP_PATH not found. Install Claude desktop first." >&2
  exit 1
fi

if [ ! -f "$ASSETS_CAR" ]; then
  echo "error: $ASSETS_CAR not found." >&2
  exit 1
fi

# iconutil can read Assets.car directly and extract the named icon family.
# The "Claude" name selects the app icon asset group (not electron.icns fallback).
iconutil --convert iconset --output "$ICONSET" "$ASSETS_CAR" Claude

icon_count=$(find "$ICONSET" -name "*.png" | wc -l | tr -d ' ')
echo "extracted $icon_count PNG frames from Assets.car"

if [ "$icon_count" -lt 6 ]; then
  echo "error: expected at least 6 icon frames, got $icon_count" >&2
  exit 1
fi

iconutil --convert icns --output "$OUT" "$ICONSET"
echo "wrote $OUT ($(du -h "$OUT" | cut -f1))"

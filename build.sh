#!/bin/bash
# Build SpaceArt.saver on a Mac with Xcode Command Line Tools installed.
# No Xcode project needed — this compiles the Swift source directly.
set -euo pipefail
cd "$(dirname "$0")"

NAME="SpaceArt"
OUT="$NAME.saver"

rm -rf "$OUT"
mkdir -p "$OUT/Contents/MacOS" "$OUT/Contents/Resources"

swiftc -module-name "$NAME" \
  -O \
  -emit-library \
  -o "$OUT/Contents/MacOS/$NAME" \
  -framework ScreenSaver -framework Cocoa -framework QuartzCore \
  Sources/SpaceArtView.swift

cp Resources/*.jpg "$OUT/Contents/Resources/"
cp Info.plist "$OUT/Contents/"

echo "Built $OUT"
echo "Double-click it to install, or run ./install.sh"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

swift build -c release

APP_DIR="$ROOT_DIR/dist/SickMotion.app"
BIN_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

rm -rf "$APP_DIR"
mkdir -p "$BIN_DIR" "$RESOURCES_DIR"

cp "$ROOT_DIR/.build/release/sickmotion-menubar" "$BIN_DIR/SickMotion"
chmod +x "$BIN_DIR/SickMotion"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>SickMotion</string>
  <key>CFBundleIdentifier</key>
  <string>com.sickmotion.menubar</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>SickMotion</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>Sick Motion uses location updates to estimate vehicle acceleration and turning for motion cues.</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

cp "$ROOT_DIR/.build/release/sickmotionctl" "$ROOT_DIR/dist/sickmotionctl"
chmod +x "$ROOT_DIR/dist/sickmotionctl"

echo "Built app bundle at: $APP_DIR"
echo "Built CLI at: $ROOT_DIR/dist/sickmotionctl"

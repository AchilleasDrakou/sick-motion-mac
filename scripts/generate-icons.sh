#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/raycast-extension"
ASSETS_DIR="$OUT_DIR/assets"
mkdir -p "$ASSETS_DIR"

# Light-theme base icon (used by Raycast by default)
magick -size 512x512 xc:none \
  \( -size 512x512 gradient:'#F6F6F6-#DADADA' \) -compose over -composite \
  -fill 'rgba(0,0,0,0.08)' -draw 'circle 256,256 256,54' \
  -stroke 'rgba(36,36,36,0.92)' -strokewidth 16 -fill none -draw 'circle 256,256 256,132' \
  -stroke none -fill 'rgba(20,20,20,0.96)' -draw 'circle 256,256 256,226' \
  -fill 'rgba(66,66,66,0.92)' \
  -draw 'circle 256,82 256,95' \
  -draw 'circle 256,108 256,118' \
  -draw 'circle 256,430 256,417' \
  -draw 'circle 256,404 256,394' \
  -draw 'circle 82,256 95,256' \
  -draw 'circle 108,256 118,256' \
  -draw 'circle 430,256 417,256' \
  -draw 'circle 404,256 394,256' \
  "$ASSETS_DIR/icon.png"

# Dark-theme alternate icon (for dark appearance mode)
magick -size 512x512 xc:none \
  \( -size 512x512 gradient:'#121212-#2B2B2B' \) -compose over -composite \
  -fill 'rgba(255,255,255,0.08)' -draw 'circle 256,256 256,54' \
  -stroke 'rgba(224,224,224,0.92)' -strokewidth 16 -fill none -draw 'circle 256,256 256,132' \
  -stroke none -fill 'rgba(244,244,244,0.96)' -draw 'circle 256,256 256,226' \
  -fill 'rgba(204,204,204,0.92)' \
  -draw 'circle 256,82 256,95' \
  -draw 'circle 256,108 256,118' \
  -draw 'circle 256,430 256,417' \
  -draw 'circle 256,404 256,394' \
  -draw 'circle 82,256 95,256' \
  -draw 'circle 108,256 118,256' \
  -draw 'circle 430,256 417,256' \
  -draw 'circle 404,256 394,256' \
  "$ASSETS_DIR/icon@dark.png"

echo "Generated: $ASSETS_DIR/icon.png"
echo "Generated: $ASSETS_DIR/icon@dark.png"

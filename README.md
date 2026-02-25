# Sick Motion (macOS + Raycast)

This repo contains:

- A macOS menu bar app that overlays animated edge dots (inspired by iPhone Vehicle Motion Cues).
- A Raycast extension to toggle/enable/disable the overlay.

## 1) Build the menu bar `.app` + CLI

From the repo root:

```bash
./scripts/build-app-bundle.sh
```

Outputs:

- `dist/SickMotion.app`
- `dist/sickmotionctl`

Launch the app:

```bash
open dist/SickMotion.app
```

You should see a `car` icon in the macOS menu bar.

## 2) Optional: run the menu bar app directly from SwiftPM

From the repo root:

```bash
swift build -c release
swift run sickmotion-menubar
```

## 3) Install the control CLI

In another terminal:

```bash
cp dist/sickmotionctl /usr/local/bin/sickmotionctl
```

If `/usr/local/bin` is not on your machine, use `/opt/homebrew/bin`.

Then test:

```bash
sickmotionctl toggle
sickmotionctl enable
sickmotionctl disable
```

## 4) Use the Raycast extension

Inside `raycast-extension`:

```bash
bun install
bun run dev
```

Raycast commands:

- `Toggle Motion Dots`
- `Enable Motion Dots`
- `Disable Motion Dots`

If Raycast cannot find `sickmotionctl`, set the extension preference `sickMotionCtlPath`.

## Notes

- The overlay is non-interactive and click-through.
- It appears on all screens and across spaces.
- This implementation uses smooth animated edge dots as a macOS adaptation.

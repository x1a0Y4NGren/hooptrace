# HoopTrace Icon Assets

The launcher icon uses a near-black court-inspired field and a compact basketball-to-hoop trace mark. It was created specifically for HoopTrace during the 2026 release-preparation phase with OpenAI's built-in ImageGen tool and contains no third-party artwork.

## Generation

Mode: built-in ImageGen, `logo-brand` use case (not the CLI fallback).

Final selected prompt:

```text
Use case: logo-brand
Asset type: square mobile app launcher icon foreground source with true transparency
Primary request: Create one centered, minimal geometric basketball mark for HoopTrace: a basketball hoop and backboard in warm white, an arena-orange basketball at the upper left, and one continuous arena-orange shot trace curving from the ball into the hoop.
Scene/backdrop: fully transparent canvas; no background shape and no baked outer icon container.
Subject: simplified front-facing basketball backboard and hoop; the ball and continuous trace must remain distinct and recognizable at 32 px.
Style/medium: crisp flat vector-like logo rendered as a high-resolution raster; minimal silhouette; heavy square-ended strokes; generous negative space.
Composition/framing: square composition, optically centered as one balanced mark, with ample clear margin on every side for Android adaptive circle, rounded-square, and squircle masks; nothing clipped.
Color palette: use only warm white #F4F3EF and arena orange #FF5A1F; transparent elsewhere.
Constraints: exactly one basketball, one continuous shot trace entering the hoop, and one hoop/backboard assembly; clean simple geometry; strong small-size legibility; true alpha transparency.
Avoid: text, letters, lettermarks, red or blue player dots, a full basketball court, extra balls, extra traces, extra court markings, gradients, shadows, glow, paper texture, distressing, 3D effects, photorealism, watermark, border, background fill, and baked rounded outer corners.
```

Palette:

- Near-black background: `#101112`
- Warm-white mark: `#F4F3EF`
- Arena-orange ball and trace: `#FF5A1F`

## File roles and derivation

- `hooptrace-app-icon-foreground.png` is the normalized 1024 x 1024 transparent project source. Its visible mark is centered within a 620 x 620 launcher safe zone.
- `hooptrace-app-icon.png` is the opaque 1024 x 1024 master, composited over the exact near-black background.
- Android legacy mipmaps and every iOS AppIcon PNG are opaque Lanczos resizes of the composite master.
- Android adaptive foreground and monochrome PNGs use 108, 162, 216, 324, and 432 pixel canvases for mdpi through xxxhdpi. The monochrome asset reuses the source alpha as one warm-white color.
- `tool/release/generate_launcher_icons.py` performs source normalization (when given a transparent built-in ImageGen result), compositing, Lanczos resizing, platform output generation, and contact-sheet generation. It requires Pillow and does not add a Flutter package dependency.

The source, master, derivatives, and generation script are distributed under the repository MIT License.

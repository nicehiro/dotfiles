---
name: manim
description: Create mathematical/technical animations and figures with Manim Community Edition in 3b1b style. Use for publication-quality paper figures (true vector SVG/PDF export), talk videos, explainer animations, or any request to visualize/animate math, algorithms, ML, or robotics concepts. Includes 3b1b style presets and a visual QA loop via frame extraction.
---

# Manim (CE) — 3b1b-style figures and animations

Skill dir: `~/.pi/agent/skills/manim` (referred to as `$SKILL` below).
All manim commands use the bundled venv: `$SKILL/.venv/bin/manim` and
`$SKILL/.venv/bin/python`. Never install manim into the user's project.

## Setup (once)

```bash
$SKILL/scripts/setup.sh
```

Verifies system deps (ffmpeg, LaTeX, cairo/pango, pkg-config), creates
`$SKILL/.venv`, installs manim CE. If it reports missing brew packages,
install them and re-run.

## Scene file conventions

- Work in a scratch dir (`/tmp/manim-<task>/` or the user's project if they
  want to keep sources). Pass `--media_dir <scratch>/media` so renders never
  pollute the cwd; clean up scratch output when done.
- Start every scene file with the style preset:

```python
import sys
sys.path.insert(0, "/Users/fangyuan/.pi/agent/skills/manim/assets")
from manim import *
from style_3b1b import *

use_video_theme()   # videos/talks: black bg, bright palette
# use_paper_theme() # paper figures: white bg, black defaults, use *_D/*_E colors
```

Read `references/style-guide.md` for the 3b1b visual language before writing
scenes. Consult `references/cheatsheet.md` for CE 0.21 API (your training data
may contain stale or ManimGL-flavored API — CE is not ManimGL).

## Workflow A — static paper figure

1. `use_paper_theme()`; build the scene with only `self.add(...)` (no
   animations). Keep everything a VMobject (no `ImageMobject`) so vector
   export works.
2. Iterate with fast raster previews, **reading the PNG after every render**:
   ```bash
   $SKILL/.venv/bin/manim render -s -ql --media_dir <scratch>/media scene.py FigName
   ```
3. When the layout is right, export true vector output:
   ```bash
   $SKILL/.venv/bin/python $SKILL/scripts/export_vector.py scene.py FigName fig.svg
   $SKILL/.venv/bin/python $SKILL/scripts/export_vector.py scene.py FigName fig.pdf
   ```
   Default background is transparent; add `--background white` if needed.
   The PDF drops straight into LaTeX via `\includegraphics`.
4. Verify the vector file visually: `rsvg-convert -b white -w 900 fig.svg -o check.png`
   (or `pdftoppm -png -r 100 fig.pdf check`) and read it. A white-background
   check catches light-on-white invisibility.
5. Fallback for scenes with raster content: high-res transparent PNG
   `manim render -s -qk -t ...`.

## Workflow B — video (talk / explainer)

1. `use_video_theme()`; write the scene with animations.
2. Iterate at low quality:
   ```bash
   $SKILL/.venv/bin/manim render -ql --media_dir <scratch>/media scene.py SceneName
   $SKILL/scripts/frames.sh <scratch>/media/videos/<file>/480p15/SceneName.mp4 6
   ```
   Read the contact sheet PNG. Check: layout, overlaps, clipping, animation
   staging order, elements left on screen that should have faded out.
3. For timing-sensitive segments extract more frames (`frames.sh video 12`).
4. Final render: `-qh` (1080p60) or `-qk` (4K). Deliver the mp4 path.

## Visual QA loop (non-negotiable)

Never declare a render done without reading the output image. Every
iteration: render low quality → read PNG/contact sheet → fix → repeat.
Common issues to look for: overlapping labels, text clipped at frame edge,
bad color contrast, elements not cleaned up between sections.

## References

- `references/style-guide.md` — 3b1b visual language: palette rules, animation grammar, pacing
- `references/cheatsheet.md` — Manim CE 0.21 API quick reference
- `references/pitfalls.md` — common errors and fixes

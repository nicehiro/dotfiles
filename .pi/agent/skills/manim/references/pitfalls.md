# Common Pitfalls

## API confusion
- **ManimGL ≠ CE.** `ShowCreation`→`Create`, `TexMobject`→`MathTex`,
  `TextMobject`→`Tex`, `GlowDot`→use `style_3b1b.glow_dot`. If an attribute
  error looks like a renamed class, check the cheatsheet first.
- `self.play(mob.shift, RIGHT)` (old style) → `self.play(mob.animate.shift(RIGHT))`.

## LaTeX
- `Tex` wraps content in text mode; `MathTex` in math mode. `Tex(r"$x$ is small")` for mixed.
- LaTeX errors surface as `LatexError` with a log path — read the log; usually
  a missing `\usepackage`. Add packages via
  `TexTemplate` : `t = TexTemplate(); t.add_to_preamble(r"\usepackage{bm}"); MathTex(r"\bm{x}", tex_template=t)`.
- Double-subscript style errors come from un-braced scripts: `\theta_{t+1}` not `\theta_t+1`.
- Manim caches compiled tex in `media/Tex/`; corrupted cache → delete that dir.

## Layout
- Mobjects spawn at ORIGIN and overlap by default. Position everything
  explicitly (`next_to`, `arrange`, `to_edge`).
- `VGroup` only accepts VMobjects; `ImageMobject` needs `Group`.
- Draw order = add order; override with `set_z_index`. Fills of later shapes
  cover earlier strokes.
- Long `MathTex` can overflow the frame — check edges in the rendered image,
  `scale_to_fit_width(config.frame_width - 1)` if needed.

## Animation
- `Transform(a, b)` keeps `a` (mutated) in the scene — later references to
  `b` are not on screen. Prefer `ReplacementTransform` or keep using `a`.
- Animating a mobject that was never `self.add`-ed nor introduced by an
  intro animation: `FadeIn`/`Create` first (or `self.add`).
- Updaters run every frame including during unrelated animations; remove with
  `clear_updaters()` when done, or they will fight later `move_to` calls.
- `.animate` interpolates start→end states; for rotation this shrinks through
  the middle — use `Rotate(mob, angle)` instead of `mob.animate.rotate`.

## Rendering
- Partial render for fast iteration on long scenes: `-n start,end` renders
  only those animation indices.
- `--flush_cache` clears stale partial-movie cache when edits seem to have
  no effect.
- Section markers: `self.next_section("name")` + `--save_sections` for
  per-section outputs.

## Vector export (`scripts/export_vector.py`)
- VMobjects only; `ImageMobject`/point clouds are skipped with a warning —
  the scene must avoid them for paper figures.
- Scene is rendered with `dry_run`, so `construct` runs fully; animations
  are fine but only the **final** state is exported.
- Default background is transparent. Light-colored (white/yellow) elements
  are invisible on paper — use `use_paper_theme()` and dark shades.
- Uses manim internals (`Camera.display_vectorized`); if a manim upgrade
  breaks it, re-check `manim/camera/camera.py` method names.

## Environment
- Always use `$SKILL/.venv/bin/manim`, never a global manim.
- `use_paper_theme()` calls `set_default` which persists for the whole
  process — don't mix paper and video scenes in one render invocation.

# 3b1b Visual Language

How Grant Sanderson's videos actually look, translated to Manim CE.

## Color

CE ships his palette. Usage conventions:

| Color | Role |
|---|---|
| `BLUE` (#58C4DD) | primary objects: curves, main shapes, "the thing being explained" |
| `YELLOW` | emphasis: highlights, arrows pointing at things, the current focus |
| `GREEN` | positive / correct / second object in a comparison |
| `RED` | negative / error / warnings / gradients & derivatives |
| `TEAL`, `GOLD`, `MAROON`, `PURPLE` | additional distinct entities |
| `GREY_B`..`GREY_D` | de-emphasized/background elements, axes, grid lines |
| `WHITE` | text and formulas (video theme) |

Shade variants: `_A` lightest → `_E` darkest. On black backgrounds use the
bright defaults; on white (paper theme) use `_D`/`_E` variants.

Semantic consistency matters: once a quantity has a color, every occurrence
of it — in formulas, labels, and plots — keeps that color. Use
`MathTex(r"...", substrings_to_isolate=["x"])` + `set_color_by_tex` or
`tex_to_color_map` to color parts of formulas.

## Typography

- All math and most text: LaTeX (`MathTex` / `Tex`) — Computer Modern is the
  3b1b look. Use `Text` only when LaTeX is inappropriate (e.g. CJK).
- Titles: `Title("...")` (underlined, top of frame) or `Tex` scaled ~1.2.
- Formula sizes: default 48; annotations `font_size=36`.

## Composition

- Pure black background (`use_video_theme()`).
- One idea on screen at a time; fade out what is no longer needed.
- Generous margins — keep content off frame edges (`to_edge`, `to_corner`
  with default buffs).
- Thin-ish strokes: default stroke width 4 for curves, 2 for auxiliary lines.
- Fills are translucent: `fill_opacity=0.5` for shapes whose outline matters.
- De-emphasize with opacity: `mob.animate.set_opacity(0.3)` for the
  not-currently-discussed.

## Animation grammar

| Intent | Animation |
|---|---|
| text/formula appears | `Write` |
| shape/curve appears | `Create` |
| object appears whole | `FadeIn(mob, shift=UP*0.3)` (small shift, not scale) |
| object leaves | `FadeOut` |
| formula evolves | `TransformMatchingTex` (or `ReplacementTransform`) |
| object morphs | `Transform` / `ReplacementTransform` |
| attention | `Indicate`, `Circumscribe`, `FocusOn`, or `Create(highlight(mob))` |
| many similar items | `LaggedStart(*anims, lag_ratio=0.1)` |
| continuous motion | `mob.animate.…` with a non-linear rate_func |

Rate functions: `smooth` is default and correct most of the time;
`ease_out_quad`/`ease_in_out_cubic` for physical motion; avoid `linear`
except for constant-rate processes (rotation, dashes flowing).

## Pacing

- `self.wait(0.5)`–`wait(1)` after every completed thought; `wait(2)` after
  a key formula lands.
- `run_time`: 1s default; 2–3s for morphs the viewer must follow; don't
  exceed 3s unless tracing something slow.
- Simultaneous related changes go in one `self.play(...)` call.

## Signature devices

- `glow_dot(point)` (from style_3b1b) — the glowing point marker.
- `highlight(mob)` — yellow surrounding rectangle.
- `Brace(mob, direction)` + `brace.get_tex(...)` for annotating spans.
- `NumberPlane` with faded grid (`background_line_style` opacity ~0.3) when
  coordinates matter; bare `Axes` otherwise.
- `always_redraw` + `ValueTracker` for quantities that vary continuously.

## Paper-figure adaptation

- `use_paper_theme()`: white bg, black text/axes, `_D`/`_E` colored elements.
- No glow effects (additive glow needs dark bg) — use plain `Dot`.
- Everything must stay VMobject for vector export.
- Match font size to the paper column width: after `\includegraphics`, the
  effective label size should be close to \small–\footnotesize of the paper.

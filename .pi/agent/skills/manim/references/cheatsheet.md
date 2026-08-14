# Manim CE 0.21 Quick Reference

CE, not ManimGL. Key differences from ManimGL/old manim: `Create` (not
`ShowCreation`), `config` object (not constants file), `Mobject.animate` (not
`ApplyMethod`), `Tex`/`MathTex` (not `TexMobject`/`TextMobject`).

## CLI

```bash
manim render [flags] scene.py SceneName
  -s            save last frame only (static image)
  -t            transparent background
  -ql/-qm/-qh/-qk   480p15 / 720p30 / 1080p60 / 4K60
  --media_dir DIR   output root
  --format gif|mp4|png|webm
  -n 3,6        render only animations 3..5 (partial preview)
```

Output lands in `media_dir/videos/<file>/<quality>/SceneName.mp4` or
`media_dir/images/<file>/SceneName_ManimCE_*.png`.

## Frame geometry

Frame is 8 units tall, ~14.22 wide. `ORIGIN`, `UP`, `DOWN`, `LEFT`, `RIGHT`,
`UL/UR/DL/DR`; edges at `x=±7.11`, `y=±4`.

## Positioning

```python
mob.move_to(point_or_mob)        # center on
mob.next_to(mob2, RIGHT, buff=0.25)
mob.to_edge(UP, buff=0.5); mob.to_corner(DR)
mob.shift(2*RIGHT + UP)
mob.align_to(mob2, LEFT)
mob.scale(1.5).rotate(PI/4)
VGroup(a, b, c).arrange(DOWN, buff=0.3, aligned_edge=LEFT)
VGroup(*mobs).arrange_in_grid(rows=2, cols=3)
```

## Common mobjects

```python
Circle(radius=1, color=BLUE, fill_opacity=0.5)
Square(side_length=2); Rectangle(width=3, height=1); RoundedRectangle(corner_radius=0.2)
Line(A, B); Arrow(A, B, buff=0); DoubleArrow; DashedLine
Dot(point, color=RED); Polygon(*points); Arc(angle=PI/2)
Text("hello", font_size=36)                 # pango, any system font
Tex(r"some \LaTeX text"); MathTex(r"\int_0^1 x^2\,dx")
MathTex(r"a^2+b^2", tex_to_color_map={"a": BLUE, "b": GREEN})
SurroundingRectangle(mob, color=YELLOW, buff=0.1)
Brace(mob, DOWN).get_tex(r"n")
SVGMobject("file.svg"); ImageMobject("img.png")   # ImageMobject = raster, no vector export
Table([["a","b"],["c","d"]]); MobjectMatrix; DecimalNumber(3.14, num_decimal_places=2)
Code(code_string="...", language="python")
```

## Plotting

```python
ax = Axes(x_range=[-3, 3, 1], y_range=[0, 5, 1], x_length=8, y_length=4.5,
          axis_config={"include_numbers": True})
curve = ax.plot(lambda x: x**2, color=BLUE, x_range=[-2, 2])
area  = ax.get_area(curve, x_range=[0, 1], opacity=0.4)
ax.c2p(x, y)   # data coords -> scene point;  ax.p2c(point) inverse
ax.get_axis_labels(x_label="t", y_label="v")
graph_label = ax.get_graph_label(curve, label=r"f(x)", x_val=2)
NumberPlane(background_line_style={"stroke_opacity": 0.3})
BarChart(values=[3, 5, 2], bar_names=["a", "b", "c"])
NumberLine(x_range=[0, 10, 1])
```

3D: `class S(ThreeDScene)`, `ThreeDAxes`, `Surface`,
`self.set_camera_orientation(phi=75*DEGREES, theta=30*DEGREES)`,
`self.begin_ambient_camera_rotation(rate=0.1)`.

## Animations

```python
self.play(Create(shape), Write(tex), FadeIn(mob, shift=UP*0.3), FadeOut(mob))
self.play(Transform(a, b))              # a becomes b (a stays in scene)
self.play(ReplacementTransform(a, b))   # b replaces a
self.play(TransformMatchingTex(eq1, eq2))
self.play(mob.animate.shift(RIGHT).set_color(RED), run_time=2)
self.play(Indicate(x), Circumscribe(eq), Flash(dot), Wiggle(mob))
self.play(LaggedStart(*[FadeIn(m) for m in mobs], lag_ratio=0.15))
self.play(AnimationGroup(a1, a2), Succession(a1, a2))
self.play(MoveAlongPath(dot, curve), Rotate(mob, PI/2, about_point=ORIGIN))
self.wait(1)
self.add(mob); self.remove(mob)         # instant, no animation
```

`rate_func=rate_functions.<smooth|linear|ease_in_out_cubic|ease_out_quad|there_and_back>`

## Updaters and trackers

```python
t = ValueTracker(0)
dot = always_redraw(lambda: Dot(ax.c2p(t.get_value(), f(t.get_value()))))
self.add(dot)
self.play(t.animate.set_value(3), run_time=2)

label.add_updater(lambda m: m.next_to(dot, UP))
label.clear_updaters()
```

## Camera (2D zoom/pan)

```python
class S(MovingCameraScene):
    def construct(self):
        self.play(self.camera.frame.animate.scale(0.5).move_to(target))
        self.play(Restore(self.camera.frame))  # after self.camera.frame.save_state()
```

## Scene state

```python
mob.save_state(); self.play(Restore(mob))
mob.copy()
mob.set_z_index(1)      # draw order override
self.bring_to_front(mob); self.bring_to_back(mob)
```

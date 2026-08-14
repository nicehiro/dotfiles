"""3b1b visual style presets for manim CE.

Manim CE already ships Grant Sanderson's palette (BLUE=#58C4DD, YELLOW=#FFFF00,
GREEN=#83C167, RED=#FC6255, TEAL, GOLD, MAROON, PURPLE + _A.._E shade variants).
This module adds the two theme setups and a few idiomatic helpers.

Usage (scene file lives anywhere; add this file's directory to sys.path or copy
it next to the scene):

    from style_3b1b import *
    use_video_theme()   # or use_paper_theme()
"""

from manim import (
    BLACK,
    WHITE,
    YELLOW,
    Circle,
    MathTex,
    SurroundingRectangle,
    Tex,
    Text,
    VGroup,
    VMobject,
    config,
)
from manim.utils.color import ManimColor

__all__ = [
    "use_video_theme",
    "use_paper_theme",
    "glow_dot",
    "highlight",
]


def use_video_theme():
    """Pure black background, light-on-dark — 3b1b's video look."""
    config.background_color = BLACK


def use_paper_theme():
    """White background, dark-on-light — for paper figures and vector export.

    Flips the default color of all VMobjects (incl. Tex/MathTex/Text) to
    black so light-on-dark scenes don't render invisible on white.
    Use the darker shade variants (BLUE_D/BLUE_E etc.) for colored elements;
    the bright defaults are tuned for black backgrounds.
    """
    config.background_color = WHITE
    VMobject.set_default(color=BLACK)
    Tex.set_default(color=BLACK)
    MathTex.set_default(color=BLACK)
    Text.set_default(color=BLACK)


def glow_dot(point=(0, 0, 0), color=YELLOW, radius=0.2, n_layers=20):
    """3b1b-style glowing dot (CE has no GlowDot). Video theme only —
    the additive-glow look needs a dark background."""
    color = ManimColor(color)
    return VGroup(
        *(
            Circle(
                radius=radius * (i + 1) / n_layers,
                stroke_width=0,
                fill_color=color,
                fill_opacity=1.5 / n_layers,
            ).move_to(point)
            for i in range(n_layers)
        )
    )


def highlight(mobject, color=YELLOW, buff=0.1):
    """Yellow surrounding rectangle, the standard 3b1b emphasis device."""
    return SurroundingRectangle(mobject, color=color, buff=buff)

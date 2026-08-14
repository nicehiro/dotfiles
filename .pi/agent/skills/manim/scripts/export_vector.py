#!/usr/bin/env python
"""Export a static manim scene as true vector SVG or PDF.

Reuses manim's Cairo path/stroke/fill logic but targets a vector surface
instead of the raster ARGB32 buffer. VMobjects only (geometry + Tex/MathTex/
Text are all VMobjects); ImageMobject and point clouds are skipped with a
warning.

Usage:
    export_vector.py scene.py SceneName output.svg
    export_vector.py scene.py SceneName output.pdf --background '#FFFFFF'

Depends on manim internals (Camera.display_vectorized and friends); verified
against manim CE 0.21. If a manim upgrade breaks this, check
manim/camera/camera.py for renamed methods.
"""

from __future__ import annotations

import argparse
import importlib.util
import itertools as it
import sys
import types
from pathlib import Path

import cairo
import numpy as np


def vector_safe_set_color(self, ctx, rgbas, vmobject):
    """Like Camera.set_cairo_context_color but without the RGB byte-order
    reversal that only applies to the raster ARGB32 surface."""
    if len(rgbas) == 1:
        ctx.set_source_rgba(*rgbas[0][:3], rgbas[0][3])
    else:
        points = vmobject.get_gradient_start_and_end_points()
        points = self.transform_points_pre_display(vmobject, points)
        pat = cairo.LinearGradient(*it.chain(*(point[:2] for point in points)))
        offsets = np.linspace(0, 1, len(rgbas))
        for rgba, offset in zip(rgbas, offsets):
            pat.add_color_stop_rgba(offset, *rgba[:3], rgba[3])
        ctx.set_source(pat)
    return self


def export_scene_vector(scene, out_path: Path, background: str | None) -> None:
    from manim.mobject.types.vectorized_mobject import VMobject
    from manim.utils.color import ManimColor

    cam = scene.camera
    pw, ph = cam.pixel_width, cam.pixel_height
    fw, fh = cam.frame_width, cam.frame_height
    fc = cam.frame_center

    if out_path.suffix == ".svg":
        surface = cairo.SVGSurface(str(out_path), pw, ph)
        surface.set_document_unit(cairo.SVGUnit.PX)
    elif out_path.suffix == ".pdf":
        surface = cairo.PDFSurface(str(out_path), pw, ph)
    else:
        sys.exit(f"unsupported output format: {out_path.suffix} (use .svg or .pdf)")

    ctx = cairo.Context(surface)
    ctx.set_matrix(
        cairo.Matrix(
            pw / fw, 0,
            0, -(ph / fh),
            pw / 2 - fc[0] * (pw / fw),
            ph / 2 + fc[1] * (ph / fh),
        )
    )

    if background:
        ctx.set_source_rgba(*ManimColor(background).to_rgba())
        ctx.paint()

    cam.set_cairo_context_color = types.MethodType(vector_safe_set_color, cam)

    skipped = []
    for mob in cam.get_mobjects_to_display(scene.mobjects):
        if isinstance(mob, VMobject):
            if len(mob.points) > 0:
                cam.display_vectorized(mob, ctx)
                ctx.new_path()
        else:
            skipped.append(type(mob).__name__)

    surface.finish()

    if skipped:
        print(f"WARNING: skipped non-vector mobjects: {sorted(set(skipped))}")
    print(f"wrote {out_path}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("scene_file", type=Path)
    parser.add_argument("scene_name")
    parser.add_argument("output", type=Path)
    parser.add_argument(
        "--background",
        default=None,
        help="background color e.g. '#FFFFFF' or 'black'; default transparent",
    )
    args = parser.parse_args()

    from manim import config, tempconfig

    scene_dir = str(args.scene_file.resolve().parent)
    sys.path.insert(0, scene_dir)
    spec = importlib.util.spec_from_file_location("_export_target", args.scene_file)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    scene_cls = getattr(module, args.scene_name, None)
    if scene_cls is None:
        sys.exit(f"scene {args.scene_name!r} not found in {args.scene_file}")

    with tempconfig({"dry_run": True}):
        scene = scene_cls()
        scene.render()
        export_scene_vector(scene, args.output, args.background)


if __name__ == "__main__":
    main()

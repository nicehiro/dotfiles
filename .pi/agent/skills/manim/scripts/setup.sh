#!/usr/bin/env bash
# One-time setup for the manim skill: checks system deps, creates the venv,
# installs manim CE, runs a smoke test.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SKILL_DIR"

missing=()
command -v uv >/dev/null || missing+=("uv")
command -v ffmpeg >/dev/null || missing+=("ffmpeg (brew install ffmpeg)")
command -v latex >/dev/null || missing+=("latex (MacTeX/TeX Live, needed for Tex/MathTex)")
command -v pkg-config >/dev/null || missing+=("pkg-config (brew install pkgconf)")
pkg-config --exists cairo pango 2>/dev/null || missing+=("cairo/pango (brew install cairo pango)")

if [ ${#missing[@]} -gt 0 ]; then
    printf 'Missing dependencies:\n'
    printf '  - %s\n' "${missing[@]}"
    exit 1
fi

# Vector-output QA (Workflow A step 4) needs one of these rasterizers.
if ! command -v rsvg-convert >/dev/null && ! command -v pdftoppm >/dev/null; then
    echo "WARNING: neither rsvg-convert (brew install librsvg) nor pdftoppm (brew install poppler) found;"
    echo "         vector-export QA in Workflow A will not work until one is installed."
fi

if [ ! -x .venv/bin/python ]; then
    uv venv .venv --python 3.12
fi
# export_vector.py depends on manim CE 0.21 Camera internals; keep pinned in sync.
uv pip install --python .venv/bin/python 'manim~=0.21.0'

.venv/bin/python -c "import manim; print('manim', manim.__version__, 'OK')"

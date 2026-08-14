#!/usr/bin/env bash
# Extract N evenly spaced frames from a video into a single contact sheet PNG
# for visual QA.
#
# Usage: frames.sh video.mp4 [N] [out.png]
#   N defaults to 6; out defaults to <video>_frames.png
set -euo pipefail

video="$1"
n="${2:-6}"
out="${3:-${video%.*}_frames.png}"

duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$video")
cols=$(python3 -c "import math; print(math.ceil(math.sqrt($n)))")
rows=$(python3 -c "import math; print(math.ceil($n / $cols))")

# Sample frame i at (i + 0.5) * duration / N to avoid identical first/last frames.
ffmpeg -v error -y -i "$video" \
    -vf "fps=$n/$duration:start_time=$(python3 -c "print(0.5 * $duration / $n)"),scale=480:-1,tile=${cols}x${rows}" \
    -frames:v 1 "$out"

echo "$out"

---
description: Create a manim figure or animation in 3b1b style
argument-hint: "[description of figure/animation]"
---
Load the manim skill (read ~/.pi/agent/skills/manim/SKILL.md and its
references) and create the following with Manim CE in 3b1b style:

${@:-Ask me what figure or animation I want, and whether it is a static paper figure (vector SVG/PDF), a talk video, or an explainer animation.}

Requirements:
- If it is unclear whether I want a static figure or a video, ask first.
- Static paper figures: use the paper theme and deliver vector SVG + PDF.
- Videos: use the video theme, iterate at low quality with the frame contact
  sheet, deliver the final high-quality mp4.
- Follow the visual QA loop strictly: render, read the image, fix, repeat.
  Do not deliver anything you have not visually verified.

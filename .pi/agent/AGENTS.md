# Global AGENTS.md

## About Me

PhD student in robotics. Research areas: reinforcement learning, vision-language-action models, large language models, diffusion models, and other learning related or AI related.

## Research Stack

- **Framework**: PyTorch
- **Experiment tracking**: Weights & Biases (W&B)
- **Compute**: Remote HPC cluster
- **Paper management**: Zotero + Better-BibTeX → `~/Documents/roam/library.bib` → Citar/Org-Roam in Emacs
- **Paper discovery**: FreshRSS → Emacs Elfeed with elfeed-score (`~/.config/emacs/elfeed.score`)
- **Paper writing**: LaTeX in Emacs (AUCTeX + cdlatex + reftex + yasnippet)
- **Target venues**: NeurIPS, ICML, ICLR, CoRL (conferences); TRO, TASE, RAL (journals)

## Languages & Tools

- **Research**: Python (primary), LaTeX for papers
- **Non-research projects**: Prefer native/compiled languages (Rust, C++, Go, Swift), but flexible
- **Package managers**: uv/pip for Python, homebrew on macOS

## Coding Style

- Concise code with necessary comments only
- Do NOT add comments that explain the obvious or narrate what was removed/changed
- Do NOT leave placeholder comments like `// removed X` or `# previously did Y`
- When deleting code, just delete it. No tombstone comments.

## Behavior

- Read and understand relevant code before proposing edits
- Do what's asked. Don't add unrequested features, files, or documentation
- Don't create README, docs, or markdown files unless explicitly asked
- Clean up any temporary files you create

## Refactoring & Compatibility

- I value clean code over backward compatibility
- When fixing bugs or adding features, refactoring the surrounding code for better quality is welcome
- But ask before doing a large refactor — small incidental cleanups are fine without asking
- Don't bend the design to preserve compatibility with old patterns. If the old pattern is bad, propose replacing it

## Things to Avoid

- Don't over-engineer for hypothetical future requirements
- Don't wrap everything in try/except or add defensive checks everywhere "just in case"
- Don't add type: ignore or noqa comments to silence warnings — fix the root cause
- Don't suggest degraded solutions to preserve compatibility when a clean break is better
- Never commit secrets, API keys, or credentials

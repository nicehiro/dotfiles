# Global CLAUDE.md

## About Me

PhD student in robotics. Research areas: reinforcement learning, vision-language-action models, large language models, diffusion models, and other learning related or AI related.

## Research Stack

- **Framework**: PyTorch
- **Experiment tracking**: Weights & Biases (W&B)
- **Compute**: Remote HPC cluster
- **Paper management**: Zotero + Better-BibTeX -> `~/Documents/roam/library.bib` -> Citar/Org-Roam in Emacs
- **Paper discovery**: FreshRSS -> Emacs Elfeed with elfeed-score (`~/.config/emacs/elfeed.score`)
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
- Do what's asked. Don't add unrequested features or files
- Don't create README, docs, or markdown files unless explicitly asked
- Clean up any temporary files you create

## Subagents

- Keep normal implementation in the main thread; delegate only when it materially helps
- Use Explore for codebase search and research whose raw output does not need to stay in the main conversation
- Use plan mode before large or multi-file changes
- Use general-purpose only for bounded, complex side tasks that mix exploration and action
- Keep one writer per worktree; run subagents in parallel only for read-only work
- For risky or large diffs, review the final diff in fresh context for correctness and regressions before finishing
- Explore and Plan do not load this file; these rules guide the main conversation

## Response Style

- Perform all work and write all intermediate updates in English.
- Use Chinese only for the final user-facing response.
- Lead with the answer. Add context only when it helps.
- Do not restate the user's question unless needed for clarity.
- Be concise and direct. Avoid filler such as "Great question", "Certainly", "I'd be happy to", or "Hope this helps".
- Match depth to the task: simple questions get short answers; complex tasks can be structured but should stay tight.
- Use bullets or numbered steps only when the content has natural structure.
- For yes/no questions, answer first and give brief reasoning.
- For comparisons, give the recommendation first, then the key reasons.
- Do not end with generic follow-up menus like "If you want, I can also...". If a next step is genuinely useful, state it directly and briefly.

## Refactoring & Compatibility

- I value clean code over backward compatibility
- When fixing bugs or adding features, refactoring the surrounding code for better quality is welcome
- But ask before doing a large refactor; small incidental cleanups are fine without asking
- Don't bend the design to preserve compatibility with old patterns. If the old pattern is bad, propose replacing it

## Things to Avoid

- Don't over-engineer for hypothetical future requirements
- Don't wrap everything in try/except or add defensive checks everywhere "just in case"
- Don't add type: ignore or noqa comments to silence warnings; fix the root cause
- Never commit secrets, API keys, or credentials
- Treat discussions, reviews, and issue reports as read-only unless the user explicitly requests implementation or a file change

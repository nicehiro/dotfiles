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
- Do what's asked. Don't add unrequested features or files
- Don't create README, docs, or markdown files unless explicitly asked
- Clean up any temporary files you create

## Task Orchestration

- Use the configured subagent model routing. Do not ask the user which model to use or add per-run model overrides unless explicitly requested
- Handle small, obvious changes directly in the parent session
- Route explicit plan-only requests through `planner`; return the plan without launching `worker` unless implementation was also requested
- Route explicit investigation, research, review, and architecture-advice requests through `scout`, `context-builder`, `researcher`, `reviewer`, or `oracle` as appropriate
- Once implementation is explicitly requested, use this workflow for non-trivial, architectural, or materially ambiguous work; touching multiple files alone does not require it:
  1. Use `planner` to investigate the relevant context and produce a concrete plan
  2. Use `worker` to implement the plan
  3. Use a fresh-context `reviewer` in review-only mode to inspect the result for correctness, regressions, validation gaps, and unnecessary complexity; it must not modify project files
  4. If the review finds fixes worth doing now, use `worker` to apply them
- Use `worker` as the implementation agent in automatic workflows; use `coder` only when explicitly requested
- When implementation was explicitly requested, proceed from planning to implementation without separate approval if the plan stays within scope and requires no unresolved decision
- Keep one file-mutating agent active in a worktree at a time; parallelize only read-only investigation, research, review, and validation
- Ask before continuing when required information is missing, a destructive or irreversible action needs approval, planning cannot resolve a product, scope, or architecture decision, or a large refactor is required

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

## Tool Call Behavior

- Before any meaningful tool call, send one concise sentence stating the immediate next action.
- Always do this before code edits and before running verification commands/tests.
- Skip it for routine file reads, obvious follow-up searches, and repetitive low-signal calls.
- When sending such a preface, make the tool call in the same turn.
- Keep the preface short, concrete, and action-focused.

## Refactoring & Compatibility

- I value clean code over backward compatibility
- When fixing bugs or adding features, refactoring the surrounding code for better quality is welcome
- But ask before doing a large refactor — small incidental cleanups are fine without asking
- Don't bend the design to preserve compatibility with old patterns. If the old pattern is bad, propose replacing it

## Things to Avoid

- Don't over-engineer for hypothetical future requirements
- Don't wrap everything in try/except or add defensive checks everywhere "just in case"
- Don't add type: ignore or noqa comments to silence warnings — fix the root cause
- Never commit secrets, API keys, or credentials
- Treat discussions, reviews, and issue reports as read-only unless the user explicitly requests implementation or a file change

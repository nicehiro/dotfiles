# .pi

Configuration for [Pi](https://github.com/badlogic/pi-mono), an AI coding agent.

## Structure

```
agent/
├── extensions/       Custom extensions (TypeScript)
├── skills/           Skill definitions (SKILL.md)
├── themes/           Color themes (JSON)
├── intercepted-commands/   Command wrappers (e.g. force uv over pip)
├── settings.json     Agent settings (model, theme, favorites)
├── keybindings.json  Custom keybindings
├── models.json       Custom model definitions
├── modes.json        Agent modes config
└── AGENTS.md         Project-level agent instructions
```

## Extensions

| Extension | Description |
|-----------|-------------|
| `theme-switcher.ts` | `/theme` command — switch and persist themes |
| `which-key.ts` | `Ctrl+/` — searchable keybinding reference panel |
| `safe-git/` | Git safety guards (branch protection, force-push confirmation) |
| `safe-rm.ts` | Blocks dangerous `rm` operations |
| `cwd-write-guard.ts` | Prevents writes outside the working directory |
| `uv.ts` | Intercepts pip/python to use `uv` instead |
| `context.ts` | Context injection for agent turns |
| `control.ts` | Session control utilities |
| `notify.ts` | Desktop notifications |
| `prompt-editor.ts` | External editor integration |
| `review.ts` | Code review workflow |
| `todos.ts` | Todo management |
| `whimsical.ts` | Fun extras |

## Themes

- `zed-one-dark.json` — One Dark inspired theme
- `zed-one-light.json` — One Light inspired theme
- `nightowl.json` — Night Owl theme

## Skills

- `code-review` — Confidence-scored code review
- `code-simplifier` — Code cleanup and simplification
- `feature-dev` — Guided multi-phase feature development

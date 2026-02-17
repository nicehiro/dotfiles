# .claude

Configuration for [Claude Code](https://docs.anthropic.com/en/docs/claude-code), Anthropic's CLI coding agent.

## Structure

```
settings.json       Agent settings (model, status line, plugins)
statusline.sh       Custom starship-inspired status bar script
commands/           Slash commands (prompt templates)
skills/             Installed skills/plugins
```

## Custom Commands

Academic research prompts available as `/command`:

- `literature-review` — Literature review generation
- `paper-drafter` — Academic paper drafting
- `paper-reviser` — Paper revision assistance
- `peer-reviewer` — Peer review simulation

## Skills

- `code-review` — Automated code review
- `code-simplifier` — Code cleanup
- `feature-dev` — Multi-phase feature development
- `frontend-design` — UI/frontend code generation

## Status Line

`statusline.sh` provides a custom status bar showing:
- Current model name
- Working directory
- Git branch + status indicators (`*` modified, `+` staged, `?` untracked)
- Python venv name (when active)
- Node.js version (in JS projects)
- Context window usage percentage

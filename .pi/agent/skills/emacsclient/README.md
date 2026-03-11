# emacsclient Skill

This skill lets pi drive a running Emacs instance via `emacsclient --eval`. It wraps a small set of Emacs Lisp helper functions so you (and the agent) can:

- List interactive commands by prefix
- Inspect a function's arglist and docstring
- Evaluate arbitrary elisp expressions
- Simulate key sequences as if typed
- Read the current minibuffer prompt and contents
- Inspect the current buffer name/mode/excerpt

Most of the detailed, model-facing instructions live in `SKILL.md`. This README is a quick human-oriented overview.

## Requirements

- Emacs server running (e.g. `emacs --daemon` or `M-x server-start`)
- `emacsclient` on `PATH`
- pi configured to load skills from `~/.pi/agent/skills/`

The helper elisp lives next to this README:

- `agent-skill-emacsclient.el`

## File Layout

```text
emacsclient/
├── SKILL.md                     # Agent Skill spec + detailed instructions
├── README.md                    # Human-facing overview (this file)
└── agent-skill-emacsclient.el   # Elisp helpers used via emacsclient
```

## Basic Usage (from pi)

In a pi session, the skill is available as `/skill:emacsclient` and may also be used implicitly when you ask for Emacs-related tasks.

All operations go through `emacsclient --eval` calls executed via the Bash tool. The general pattern is:

```bash
emacsclient --eval '
(progn
  (load "/path/to/skills/emacsclient/agent-skill-emacsclient.el" nil t)
  (agent-skill-emacsclient-... <keyword-args>))'
```

In practice, pi will fill in `"/path/to/skills/emacsclient"` and the keyword args. Below are the main entrypoints.

### List interactive functions by prefix

```bash
emacsclient --eval '
(progn
  (load "/path/to/skills/emacsclient/agent-skill-emacsclient.el" nil t)
  (agent-skill-emacsclient-list-functions :prefix "magit-"))'
```

### Describe a function

```bash
emacsclient --eval '
(progn
  (load "/path/to/skills/emacsclient/agent-skill-emacsclient.el" nil t)
  (agent-skill-emacsclient-describe-function :name "magit-status"))'
```

### Evaluate an elisp expression

```bash
emacsclient --eval '
(progn
  (load "/path/to/skills/emacsclient/agent-skill-emacsclient.el" nil t)
  (agent-skill-emacsclient-eval-expression
   :expr "(buffer-list)"))'
```

### Execute key sequences

```bash
emacsclient --eval '
(progn
  (load "/path/to/skills/emacsclient/agent-skill-emacsclient.el" nil t)
  (agent-skill-emacsclient-execute-keys :keys "C-x C-s"))'
```

`keys` uses `kbd` format, e.g. `"C-x C-f"`, `"M-x"`, `"S c c"`.

### Inspect minibuffer and current buffer

```bash
# Minibuffer prompt + contents
emacsclient --eval '
(progn
  (load "/path/to/skills/emacsclient/agent-skill-emacsclient.el" nil t)
  (agent-skill-emacsclient-minibuffer-prompt))'

# Current buffer name/mode/excerpt
emacsclient --eval '
(progn
  (load "/path/to/skills/emacsclient/agent-skill-emacsclient.el" nil t)
  (agent-skill-emacsclient-current-buffer-state))'
```

## Notes

- Always use `emacsclient`, never `emacs` or `emacs --batch`.
- Use `--no-wait` when opening files, but `--eval` for all elisp interactions.
- For more details and the exact rules the model follows, see `SKILL.md` in this directory.

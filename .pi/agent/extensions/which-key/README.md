# pi-which-key

Searchable keybinding cheatsheet for [pi](https://github.com/badlogic/pi-mono). Inspired by Emacs [which-key](https://github.com/justbur/emacs-which-key).

Opens a bordered overlay panel showing all keybindings grouped by category, with live filtering as you type.

## Install

```bash
pi install npm:pi-which-key
```

## Usage

- Press **Ctrl+/** to open the panel
- Or type `/which-key`

### Inside the panel

| Key | Action |
|---|---|
| Type any text | Filter keybindings by key or description |
| `↑` / `↓` | Scroll |
| `PgUp` / `PgDn` | Scroll by page |
| `Ctrl+U` | Clear filter |
| `Esc` | Close |

## Categories

Keybindings are grouped into: Application, Text Input, Cursor, Deletion, Kill Ring & Clipboard, Session, Models & Thinking, Display, Message Queue, and Extension Commands.

Extension commands (registered by other extensions) are automatically included at the bottom.

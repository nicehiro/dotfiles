---
name: org-roam
description: Manage org-roam notes via Emacs — create notes, search the knowledge graph, discover connections, add backlinks, and find orphan nodes. Use when the task involves org-roam notes, paper notes (citar), or knowledge graph operations.
---

# Org-Roam Skill

Manage org-roam notes from pi: create notes, search the knowledge graph, discover connections, and add backlinks. Works with the user's Emacs + Org-roam + Citar + Zotero workflow.

## Setup

- Org-roam directory: `~/Documents/roam/` (441+ notes)
- BibTeX file: `~/Documents/roam/library.bib` (synced from Zotero via Better BibTeX)
- Emacs must be running as a daemon (emacsclient is used for all org-roam DB operations)
- Helper script: `roam.sh` in this skill directory

## Helper Script

All org-roam operations go through `roam.sh` which calls `emacsclient --eval` to interact with the live org-roam database. Run it from any directory:

```bash
SCRIPT="$SKILL_DIR/roam.sh"
```

### Available Commands

| Command | Description |
|---------|-------------|
| `search <query>` | Search nodes by title (SQL LIKE) |
| `search-full <query>` | Full-text grep across all .org files |
| `get-node <id>` | Get node info by UUID |
| `get-backlinks <id>` | Nodes that link TO this node |
| `get-forwardlinks <id>` | Nodes this node links TO |
| `orphans [limit]` | Nodes with no incoming links |
| `all-nodes` | List all nodes |
| `paper-nodes` | List nodes with cite refs (paper notes) |
| `create-note <title>` | Create a concept note |
| `create-paper-note <citekey> <title> [filetags]` | Create a paper note |
| `add-link <source-file> <target-id> <target-title>` | Append a link to a file |
| `add-link-under <source-file> <target-id> <target-title> <heading>` | Insert link under a heading |
| `suggest-links <id>` | Find related notes not yet linked |
| `open <file>` | Open file in Emacs and raise frame |
| `db-sync` | Force org-roam DB sync |

Output format is pipe-separated: `id | title | file`

## Note Types

### Concept Notes (org-roam default template)
- Filename: `YYYYMMDDHHMMSS-slug.org`
- Properties: `:ID:` only
- Created via: `create-note`

### Paper Notes (citar template)
- Filename: `<citekey>.org`
- Properties: `:ID:` and `:ROAM_REFS: @citekey`
- Created via: `create-paper-note`
- The citekey and title come from `library.bib` (query via the `zotero` tool)

## Workflows

### Creating a Paper Note
1. Use the `zotero` tool to search for the paper and get its citekey and title
2. Optionally use `arxiv_search` or `arxiv_paper` to get additional context (abstract, contributions)
3. Create the note with `create-paper-note <citekey> <title> [filetags]`
4. Use `edit` or `write` to add initial content (summary, key ideas, math)
5. Open in Emacs for the user to continue reading: `open <filepath>`

### Discovering and Adding Backlinks
1. Use `suggest-links <id>` to find related but unlinked notes
2. Present suggestions to the user with scores
3. On approval, use `add-link` or `add-link-under` to insert `[[id:UUID][Title]]` links
4. The DB syncs automatically after each link insertion

### Enriching Orphan Nodes
253+ nodes have no incoming links. To find and connect them:
1. `orphans 20` to list some orphan nodes
2. For each, `suggest-links <id>` to find where it could be linked FROM
3. Add reciprocal links where appropriate

### Searching the Knowledge Graph
- Title search: `search "reinforcement learning"`
- Full-text: `search-full "TD learning"` (greps file content)
- Graph traversal: `get-backlinks` / `get-forwardlinks` to walk the link graph

## Important Notes

- Always use `roam.sh` for note creation (ensures correct format + DB sync)
- Filetags format: `:tag1:tag2:` (with surrounding colons)
- LaTeX in titles is fine: `$\pi_0$` works in org-mode
- After any manual file edits, run `db-sync` to update the org-roam database
- The `open` command raises the Emacs frame — use it when the user should continue editing

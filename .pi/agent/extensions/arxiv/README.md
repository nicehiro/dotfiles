# pi-arxiv

[arXiv](https://arxiv.org/) paper search and lookup tools for [pi](https://github.com/badlogic/pi-mono).

Registers two tools the LLM can call:

- **`arxiv_search`** — Search papers by query, category, and sort order. Returns titles, authors, abstracts, dates, and PDF links.
- **`arxiv_paper`** — Fetch full details of a specific paper by ID or URL.

## Install

```bash
pi install npm:pi-arxiv
```

## Tools

### arxiv_search

| Parameter | Description |
|---|---|
| `query` | Search query, e.g. `"vision language action model"` |
| `category` | Optional category filter: `cs.RO`, `cs.LG`, `cs.CV`, `cs.AI`, `cs.CL`, `stat.ML`, etc. |
| `max_results` | Max papers to return (default 10, max 50) |
| `sort_by` | `relevance`, `lastUpdatedDate`, or `submittedDate` |
| `start` | Start index for pagination |

### arxiv_paper

| Parameter | Description |
|---|---|
| `id` | arXiv ID (`2401.12345`, `2401.12345v2`) or full URL (`https://arxiv.org/abs/2401.12345`) |

## Examples

- *"Search arXiv for recent papers on diffusion policies in robotics"*
- *"Look up arxiv paper 2303.04137"*
- *"Find cs.RO papers on sim-to-real transfer, sorted by date"*

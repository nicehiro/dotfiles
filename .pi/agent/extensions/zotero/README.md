# pi-zotero

[Zotero](https://www.zotero.org/) integration for [pi](https://github.com/badlogic/pi-mono) via [Better BibTeX](https://retorque.re/zotero-better-bibtex/).

Registers a `zotero` tool that the LLM can call to search your library, export citations, read annotations, and browse collections.

## Install

```bash
pi install npm:pi-zotero
```

## Requirements

- **Zotero** with the **Better BibTeX** plugin running (exposes a JSON-RPC server on `localhost:23119`)
- Optionally, set `BIBTEX_PATH` for offline fallback when Zotero isn't running

## Configuration

Set `BIBTEX_PATH` in your shell to enable offline BibTeX search/cite when Zotero is not running:

```bash
export BIBTEX_PATH=~/path/to/library.bib
```

If unset, offline fallback is disabled and the tool requires a running Zotero instance.

## Actions

| Action | Description |
|---|---|
| `search` | Full-text search across titles, authors, abstracts. Returns matching items with cite keys. |
| `cite` | Get BibTeX entries for specific cite keys. Use after search to get exportable references. |
| `details` | Get full metadata, notes, and PDF annotations for a cite key. |
| `collections` | Get which collections a cite key belongs to. |

## Examples

The LLM calls these automatically, but you can also prompt directly:

- *"Search my Zotero library for papers on diffusion policies"*
- *"Get the BibTeX for chi2024diffusion"*
- *"Show me the annotations on my copy of that paper"*

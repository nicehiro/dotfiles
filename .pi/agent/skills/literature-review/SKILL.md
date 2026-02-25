---
name: literature-review
description: Search papers via Semantic Scholar and arXiv APIs, synthesize findings across a topic, identify research gaps, and generate BibTeX entries. Use when asked to survey literature, find related work, or explore what exists on a research topic.
---

# Literature Review

## Available APIs

### Semantic Scholar API (no auth required)

```bash
# Search papers
curl -s "https://api.semanticscholar.org/graph/v1/paper/search?query=YOUR_QUERY&limit=10&fields=title,authors,year,abstract,citationCount,venue,url"

# Get paper details by ID
curl -s "https://api.semanticscholar.org/graph/v1/paper/PAPER_ID?fields=title,authors,year,abstract,citationCount,references,citations"

# Search by author
curl -s "https://api.semanticscholar.org/graph/v1/author/search?query=AUTHOR_NAME"
```

### arXiv API

```bash
# Search papers (returns Atom XML)
curl -s "http://export.arxiv.org/api/query?search_query=all:YOUR_QUERY&start=0&max_results=10"

# Search by category
curl -s "http://export.arxiv.org/api/query?search_query=cat:cs.RO+AND+all:manipulation&max_results=20"
```

Relevant categories: cs.RO (robotics), cs.LG (machine learning), cs.CV (computer vision), cs.AI (AI)

### Zotero Library (via `zotero` tool)

The user's Zotero library is accessible through the `zotero` custom tool (requires Zotero + Better BibTeX running). Use this to:
- Check if papers are already in the library before recommending them
- Retrieve existing cite keys for papers the user already has
- Get BibTeX entries in the user's preferred format (Better BibTeX)
- Access PDF annotations and notes on papers

Actions:
- `zotero(action="search", query="...")` — search the library
- `zotero(action="cite", citekeys=["key1", "key2"])` — get BibTeX entries
- `zotero(action="details", citekeys=["key1"])` — get full metadata, notes, and annotations
- `zotero(action="collections", citekeys=["key1"])` — get collection membership

Falls back to searching the local BibTeX file (`~/Documents/roam/library.bib`) when Zotero is offline.

## Workflow

### 1. Scope Definition

Clarify before searching:
- What specific topic or problem?
- Time range? (default: last 3-5 years for methods, all time for seminal works)
- Target venues?
- Known seed papers to start from?

### 2. Library Check

Before external search, check what the user already has:
- Use `zotero(action="search", query="...")` with the topic keywords
- Note which relevant papers are already in the library (with their cite keys)
- This avoids recommending papers the user already knows and provides ready-to-use cite keys

### 3. Search Execution

Run searches via bash using the APIs above:
- Use multiple query variations to catch different terminology
- Filter by citation count for influential papers
- Check both Semantic Scholar (broader coverage) and arXiv (recent preprints)
- Cross-reference results with Zotero to flag papers already in the library

### 4. Paper Synthesis

For each relevant paper, extract into a table:

| Paper | Year | Venue | Key Contribution | Method | Results | Limitations | In Library? |
|-------|------|-------|------------------|--------|---------|-------------|-------------|

### 5. Thematic Grouping

Organize papers by approach or theme, not chronologically. Each group gets a paragraph explaining the line of work, common techniques, strengths, and where it falls short.

### 6. Gap Analysis

Based on the literature:
- What problems remain unsolved?
- Where do methods fail?
- What assumptions are commonly made but rarely questioned?
- What combinations haven't been tried?

### 7. BibTeX Generation

For papers already in the user's Zotero library, use `zotero(action="cite", citekeys=[...])` to get BibTeX in their preferred Better BibTeX format.

For new papers not in the library, provide BibTeX entries:
```bibtex
@inproceedings{author2024title,
  title={Paper Title},
  author={Author, First and Author, Second},
  booktitle={Conference Name},
  year={2024}
}
```

## Output Format

### Literature Review: [Topic]

**Search Queries Used**: [list queries executed]
**Papers Found**: X total, Y highly relevant

#### Summary Table
#### Thematic Analysis
#### Research Gaps
#### Key Takeaways (3-5 insights)
#### References (BibTeX)

## Important

- Never fabricate paper titles, authors, or venues. If a paper seems relevant but cannot be verified via API, say so explicitly.
- Distinguish between arXiv preprints (not peer-reviewed) and published work.
- Be honest about search limitations. API results may not be exhaustive.

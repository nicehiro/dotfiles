---
name: rebuttal
description: Analyze reviewer feedback and prepare grounded, venue-compliant rebuttals or author responses for conference submissions. Use when asked to check reviews, plan a rebuttal strategy, reply to reviewers, draft an OpenReview/CMT response, handle ICML/NeurIPS/ICLR/CoRL reviewer comments, compress replies to a hard character limit, or manage post-submission follow-up discussion threads.
---

# Rebuttal

Handle post-submission reviewer responses conservatively. Optimize for strict limits, full coverage, and zero fabrication.

## Required Inputs

Collect these before drafting:
- paper source: LaTeX, PDF, or a reliable summary from the user
- raw reviews: verbatim text with reviewer IDs when available
- venue rules: venue name, hard character or word limit, formatting constraints, and whether revised PDFs are allowed
- stage: initial rebuttal, author discussion, or follow-up round
- approved evidence: new experiments, derivations, analyses, or commitments that the user explicitly confirms may be mentioned

If venue rules or the limit are missing, stop and ask.

## Hard Gates

Do not finalize a rebuttal unless all three pass.

1. **Provenance gate**
   Every factual claim must map to one of: the submitted paper, the raw review, user-confirmed result, user-confirmed derivation, or clearly labeled future work.

2. **Commitment gate**
   Do not promise experiments, revisions, or analyses unless the user explicitly approved them.

3. **Coverage gate**
   Every reviewer concern must end as answered, intentionally deferred, or blocked on user input. No issue disappears.

## Workflow

### 1. Normalize the inputs

Create a `rebuttal/` workspace when useful. Preserve raw reviews verbatim in `rebuttal/REVIEWS_RAW.md`.

Record:
- venue and limit
- current round
- paper source used
- any approved new evidence
- unresolved ambiguities

### 2. Atomize reviewer concerns

Create `rebuttal/ISSUE_BOARD.md`.

For each atomic issue, track:
- `issue_id`
- reviewer
- short raw quote or anchor
- issue type: novelty, empirical support, baseline, theory, assumptions, clarity, reproducibility, significance, or other
- severity: critical, major, or minor
- response mode: clarification, grounded evidence, narrow concession, future-work boundary, or needs user input
- evidence source
- status

Merge duplicates across reviewers, but keep reviewer-local phrasing visible.

### 3. Build a response strategy

Create `rebuttal/STRATEGY_PLAN.md`.

Identify:
- shared themes across reviewers
- per-reviewer priorities
- blocked claims or unsupported counters
- evidence gaps that need user confirmation
- a rough space budget for opener, per-reviewer answers, and closing

Recommend what to emphasize for the likely swing reviewers, not just the loudest criticism.

### 4. Handle evidence gaps conservatively

If an issue needs new experiments, derivations, or literature checks:
- do not invent results
- do not imply the work is already done if it is not
- present the gap clearly to the user
- only run or describe extra work if the user explicitly asks for it or confirms it already exists

When literature support matters, verify references with `zotero_web`, `zotero`, `arxiv_search`, or other reliable sources before mentioning them.

### 5. Draft the rebuttal

Draft in the venue's expected format. For text-only rebuttals, default to:
- short opener thanking reviewers and summarizing the main resolutions
- per-reviewer responses with direct answers first
- short closing that states what was resolved and why the paper merits acceptance

Default paragraph pattern:
1. direct answer
2. grounded evidence from the paper or approved new evidence
3. implication for the reviewer concern

Prefer concrete numbers, ablations, and precise clarifications over rhetoric.

Concede narrowly when the reviewer is right. Do not spend much space on unwinnable arguments.

Answer supportive reviewers too. Reinforce the positive framing they already noticed.

### 6. Produce two versions when helpful

When the venue has a tight limit, prepare:
- `rebuttal/PASTE_READY.txt`: plain text, within the hard limit, ready to submit
- `rebuttal/REBUTTAL_DRAFT.md`: a richer version with optional material marked for trimming

If the user only wants analysis, stop after the issue board and strategy plan.

### 7. Validate before finalizing

Check all of the following:
- every issue is covered
- every factual statement is grounded
- every commitment is approved
- tone is respectful, confident, and non-defensive
- replies do not contradict each other
- the final version fits the exact venue limit

If over the limit, compress in this order:
1. remove redundancy
2. shorten politeness
3. tighten opener and closing
4. tighten wording within answers
5. never drop a critical answer silently

### 8. Follow-up rounds

For new reviewer comments:
- append them verbatim to `rebuttal/FOLLOWUP_LOG.md`
- link them to existing issues or add new ones
- draft a delta reply, not a full rewrite, unless the user asks for one
- re-run the same safety checks

## Style Rules

- Be direct, calm, and specific.
- Evidence beats assertion.
- Do not sound combative, evasive, or submissive.
- Do not fabricate citations, numbers, experiments, derivations, or reviewer intent.
- Distinguish clearly between what the paper already shows, what the authors can clarify in the rebuttal, and what belongs to future work.
- Respect the venue limit as a hard constraint.

## Integration with Other Skills

- Use `paper-writing` when the user also wants to revise the paper text, notation, tables, or figures.
- Use `literature-review` when a reviewer requests a broader related-work analysis.
- Use `autoresearch-create` only when the user explicitly wants supplementary experiments run in a loop.

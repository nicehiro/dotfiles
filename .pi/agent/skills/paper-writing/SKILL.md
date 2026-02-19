---
name: paper-writing
description: LaTeX academic paper writing for AI conferences (NeurIPS, ICML, ICLR, CoRL) and robotics journals (TRO, TASE, RAL). Use when asked to write, edit, or review paper sections, fix notation, generate tables/figures, manage BibTeX, or structure arguments.
---

# Paper Writing

## Context

The user is a robotics PhD student. Research areas: reinforcement learning, vision-language-action models, large language models, diffusion models.

- **Venues**: NeurIPS, ICML, ICLR, CoRL, TRO, TASE, RAL
- **BibTeX**: Managed by Zotero + Better-BibTeX, exported to `library.bib`
- **Editor**: Emacs with AUCTeX, cdlatex, reftex, yasnippet

## Writing Style

Write in flowing prose paragraphs. Never use bullet points or enumerated lists in paper text. Never use colons for introductions, em-dashes, or parentheses. Every idea should be woven into complete sentences that connect naturally. Information that might go in parentheses should be integrated into the sentence or placed in a separate sentence.

First person plural ("we") is appropriate. The writing should feel like a conversation between experts, not a formal decree.

Each sentence carries one idea. Each paragraph develops one argument. The reader should never need to re-read a sentence to understand it.

Be specific rather than vague. "Our method reduces tracking error by 23% on the KITTI benchmark" beats "our method significantly outperforms prior work." Numbers, dataset names, and concrete comparisons anchor abstract claims.

Cut ruthlessly. If a word adds nothing, remove it. "In order to" becomes "to." "It is important to note that" becomes nothing at all. "Makes use of" becomes "uses." "Is able to" becomes "can." "Carries out" becomes "performs." Hedging words like "quite" and "somewhat" usually weaken rather than qualify.

Use `\emph{}` sparingly. Structure and word choice should carry emphasis.

## Notation Conventions

- Vectors: bold lowercase `\mathbf{x}`
- Matrices: bold uppercase `\mathbf{A}`
- Sets: calligraphic `\mathcal{S}`
- Scalars: italic lowercase `x`
- Functions/operators: roman `\mathrm{f}` or just `f` depending on context
- Expectations: `\mathbb{E}`
- Distributions: `\mathcal{N}`, `\mathcal{U}`
- State, action, observation: `s, a, o` (standard RL notation)
- Policy: `\pi_\theta`
- Loss/objective: `\mathcal{L}`

When the paper already has established notation, follow it. Flag inconsistencies but don't silently change.

## Section Guidelines

### Abstract
The abstract opens by establishing why the problem matters, then states what gap exists, describes the key insight of the approach, reports the main quantitative result, and closes with the broader implication. This arc fits in 150 to 200 words. No citations. No undefined acronyms.

### Introduction
The first paragraph builds context around the broad problem and why it matters. The next two paragraphs survey what has been tried and explain why those approaches fall short. The fourth paragraph presents the key insight with "In this work, we..." The fifth states contributions, which can be written as a short paragraph or a concise list. End with a paper outline only if the venue expects it.

### Related Work
Group by theme rather than chronology. Each paragraph covers one line of work, explains its relationship to your approach, and transitions naturally to the next theme. The section ends by positioning your work within this landscape. Synthesize and contrast rather than listing papers.

### Method
Open with problem formulation and notation, then proceed through the approach in logical order. The reader should understand each piece before seeing the full system. Use `\paragraph{}` or `\subsubsection{}` for logical breaks. Equations should be motivated before they appear and explained after. A method overview figure helps readers build mental models. Algorithm blocks use `algorithmic` or `algorithm2e`.

### Experiments
Begin with setup covering datasets, metrics, implementation details, and baselines. State hypotheses explicitly before presenting results. The main comparison comes next, followed by ablations that reveal what matters and why. Every table and figure must be referenced and discussed in text. Report means and standard deviations over multiple seeds when applicable. Discussion of failure cases shows intellectual honesty.

### Conclusion
One paragraph recaps contributions without copying the abstract. One paragraph acknowledges limitations directly and suggests concrete future directions. Be honest about limitations.

## Tables and Figures

- Use `booktabs` (`\toprule`, `\midrule`, `\bottomrule`). No vertical lines.
- Bold the best result in comparison tables: `\textbf{}`
- Captions should be self-contained — reader should understand without reading the main text
- Figure captions below, table captions above
- Use `\label{fig:name}` / `\label{tab:name}` consistently

## BibTeX

- The user's bibliography is at `~/Documents/roam/library.bib` (auto-exported from Zotero via Better-BibTeX)
- Use `\cite{}`, `\citet{}`, `\citep{}` as appropriate
- When suggesting citations, provide the BibTeX key if it exists in library.bib, or provide the full entry to add

## Common LaTeX Patterns

```latex
% Figure
\begin{figure}[t]
  \centering
  \includegraphics[width=\linewidth]{figures/name.pdf}
  \caption{Description.}
  \label{fig:name}
\end{figure}

% Table
\begin{table}[t]
  \centering
  \caption{Description.}
  \label{tab:name}
  \begin{tabular}{lcc}
    \toprule
    Method & Metric 1 & Metric 2 \\
    \midrule
    Baseline & 0.0 & 0.0 \\
    Ours & \textbf{0.0} & \textbf{0.0} \\
    \bottomrule
  \end{tabular}
\end{table}

% Algorithm
\begin{algorithm}[t]
  \caption{Description}
  \label{alg:name}
  \begin{algorithmic}[1]
    \Require input
    \Ensure output
    \State ...
  \end{algorithmic}
\end{algorithm}
```

## Workflow

1. Read the existing draft (if any) to understand notation, structure, and style already in use
2. Ask what section or task to work on
3. Produce LaTeX that integrates cleanly with the existing paper
4. Flag any notation inconsistencies found

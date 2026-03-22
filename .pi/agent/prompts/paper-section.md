---
description: Draft a paper section — scout gathers codebase context, writer drafts LaTeX
---
Use the subagent tool with the chain parameter to execute this workflow:

1. First, use the "scout" agent to find all code, results, and data relevant to: $@
2. Then, use the "writer" agent to draft a LaTeX section based on the findings from the previous step (use {previous} placeholder). The section should be about: $@

Execute this as a chain, passing output between steps via {previous}.

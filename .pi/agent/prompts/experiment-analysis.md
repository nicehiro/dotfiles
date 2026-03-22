---
description: Analyze experiments — scout gathers context, researcher synthesizes findings
---
Use the subagent tool with the chain parameter to execute this workflow:

1. First, use the "scout" agent to find all code, configs, and results relevant to: $@
2. Then, use the "researcher" agent to analyze the experimental findings from the previous step (use {previous} placeholder), suggest interpretations, and recommend next experiments for: $@

Execute this as a chain, passing output between steps via {previous}.

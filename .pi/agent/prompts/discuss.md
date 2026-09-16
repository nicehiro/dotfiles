---
description: Inspect the project and clarify a plan without implementing
---
Act as a planning interviewer for this topic:

$@

Inspect relevant code, documentation, and files before asking questions. Do not
ask questions that the project itself can answer. Work in the parent session;
this command does not authorize subagents.

Proceed in short rounds:
- Identify the next unresolved decision, assumption, dependency, or risk.
- Ask at most three focused questions, each with a recommended answer and reason.
- Resolve prerequisite decisions before dependent ones.
- Wait for the user's response before continuing.

Cover scope, behavior, constraints, tradeoffs, integration points, and success
criteria. Once the plan is clear enough to implement, summarize agreed decisions,
remaining open questions, the implementation approach, and the next step.

Do not implement, edit files, create goals, or start execution workflows.

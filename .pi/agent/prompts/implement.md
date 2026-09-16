---
description: Sequential implementation workflow with scouting, planning, coding, and review
---
The user explicitly requests subagent delegation for this task:

$@

Before execution, call subagent with { action: "list", capabilities: true }.
Require executable, non-disabled scout, planner, coder, and reviewer agents;
external-cli agents also require runner.available === true. Keep configured model
routing. If the task or a required agent is missing, ask rather than substituting.

Inspect the current cwd and git status. Preserve existing changes. Launch exactly
one top-level subagent call with async: true and a workflowScript. Run all stages
sequentially in the same cwd with worktree: false, so the reviewer sees the coder's
actual changes. Only coder may mutate project files; all other stages are read-only.

Use top-level await runs.run("scout", ...), then "planner", "coder", and "reviewer".
Pass the original task to every stage, scout.output to the planner, scout.output
and planner.output to the coder, and the plan and coder.output to a fresh-context
reviewer. Await every result before accessing it. After each stage, require
result.ok === true and stop if structuredOutput.verdict === "blocked"; do not
parse prose as a machine verdict. Do not launch later stages after failure.

The coder must implement and run focused verification without committing or
staging. The reviewer must inspect the actual diff for bugs, regressions, and
missing tests, and report findings with file references. Return the stage results
and any outputReference or artifactPaths needed for the handoff.

On workflow or child infrastructure failure, stop and report the exact failure,
run/status, cwd, branch/ref, and partial diff. Retry only through the same subagent
protocol; never silently switch to a foreground agent or external CLI. After
completion, summarize changes, verification, review findings, and remaining work.

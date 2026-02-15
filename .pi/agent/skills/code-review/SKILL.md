---
name: code-review
description: Automated code review for pull requests or local changes using confidence-based scoring to filter false positives. Use when asked to review a PR, review code changes, or audit code quality.
---

# Code Review

Systematic code review with confidence-based filtering. Only reports high-confidence, actionable issues.

## Scope

By default, review the current PR (`gh pr diff`) or unstaged changes (`git diff`). User may specify different scope.

## Process

1. **Gather context**:
   - Identify the changes to review (`gh pr diff` or `git diff`)
   - Find project guidelines (AGENTS.md, CLAUDE.md, or similar) in the repo root and modified directories
   - Summarize the changes

2. **Review from multiple angles**:
   - **Guidelines compliance**: Check changes against project conventions (imports, naming, error handling, patterns)
   - **Bug detection**: Scan for obvious bugs in the changes only — logic errors, null handling, race conditions, memory leaks, security issues
   - **Historical context**: Use `git log` and `git blame` on modified files for context-based issues
   - **Comment compliance**: Check that changes comply with guidance in code comments

3. **Score each issue (0–100)**:
   - **0**: False positive, doesn't hold up to scrutiny, or pre-existing
   - **25**: Might be real but unverified; stylistic issue not in project guidelines
   - **50**: Real but minor or unlikely in practice
   - **75**: Verified, likely hit in practice, important. Directly impacts functionality or explicitly mentioned in guidelines
   - **100**: Confirmed, will happen frequently, evidence directly confirms it

4. **Filter**: Only report issues scoring **≥ 80**

5. **Output** (for PRs, post via `gh pr comment`):

```
### Code review

Found N issues:

1. <description> (<guideline reference or bug explanation>)
   <file path + line range>

2. ...
```

If no issues score ≥ 80: "No issues found."

## False Positives to Ignore

- Pre-existing issues not introduced in this change
- Issues linters/typecheckers/CI will catch
- Pedantic nitpicks a senior engineer wouldn't flag
- General quality issues unless explicitly required in guidelines
- Issues silenced by lint-ignore comments
- Functionality changes that are clearly intentional
- Issues on lines the author didn't modify

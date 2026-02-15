---
name: feature-dev
description: Guided feature development workflow with 7 phases — discovery, codebase exploration, clarifying questions, architecture design, implementation, quality review, and summary. Use for new features that touch multiple files or require architectural decisions.
---

# Feature Development

Systematic 7-phase workflow for building features. Understand the codebase, clarify requirements, design architecture, then implement.

## When to Use

- New features touching multiple files
- Features requiring architectural decisions
- Complex integrations with existing code
- Unclear or underspecified requirements

Skip this for single-line fixes, trivial changes, or urgent hotfixes.

## Phase 1: Discovery

**Goal**: Understand what needs to be built.

1. If the feature request is unclear, ask:
   - What problem are you solving?
   - What should the feature do?
   - Constraints or requirements?
2. Summarize understanding and confirm with user.

## Phase 2: Codebase Exploration

**Goal**: Understand relevant existing code and patterns.

1. Search for similar features, trace their implementations
2. Map the architecture: abstractions, layers, patterns, conventions
3. Identify key files and entry points relevant to the feature
4. Check for project guidelines (AGENTS.md, CLAUDE.md, etc.)
5. Present summary of findings: patterns, key files, architecture insights

## Phase 3: Clarifying Questions

**CRITICAL — do not skip.**

**Goal**: Resolve all ambiguities before designing.

1. Review codebase findings and the feature request
2. Identify underspecified aspects: edge cases, error handling, integration points, scope, backward compatibility, performance
3. Present all questions in an organized list
4. **Wait for answers before proceeding**

## Phase 4: Architecture Design

**Goal**: Design the implementation approach.

1. Consider multiple approaches with different trade-offs:
   - **Minimal**: Smallest change, maximum reuse of existing code
   - **Clean**: Best maintainability and abstractions
   - **Pragmatic**: Balance of speed and quality
2. For each: list files to create/modify, component responsibilities, trade-offs
3. Present a recommendation with reasoning
4. **Ask user which approach they prefer**

## Phase 5: Implementation

**Do not start without user approval.**

1. Read all relevant files identified in previous phases
2. Implement following the chosen architecture
3. Follow codebase conventions strictly
4. Write clean code

## Phase 6: Quality Review

**Goal**: Ensure code quality and correctness.

1. Review all changes for:
   - **Simplicity/DRY/elegance**: Redundancy, unnecessary complexity
   - **Bugs/correctness**: Logic errors, edge cases, null handling
   - **Conventions**: Project patterns and guidelines compliance
2. Score issues by confidence (0–100), only flag ≥ 80
3. Present findings and ask: fix now, fix later, or proceed as-is?
4. Address based on user decision

## Phase 7: Summary

1. Summarize what was built
2. Key decisions made
3. Files created/modified
4. Suggested next steps

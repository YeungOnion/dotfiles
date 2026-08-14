---
name: triage-conventions
description: Use when triaging a reported bug — explore the codebase for regression signals, then reproduce the issue in an isolated git worktree before planning a fix.
---

# Triage Conventions

## Codebase Exploration

When triaging an issue, read:

- `CLAUDE.md`/`AGENTS.md` and any `design/*.md` for project conventions and architecture
- Relevant skills (especially `ddd` for domain context) for background
- Source files related to the issue
- **Check for regression signals**: if the issue describes a bug, use `git log` on the affected files to see if they were recently changed. Check if the described behavior worked in a prior version. This informs whether to classify as `bug` or `regression`.

## Bug Reproduction

**Bugs and regressions only — skip for features.**

Before planning a fix, reproduce the issue in an isolated workspace to confirm the failure mode and understand it firsthand.

a. **Create an isolated worktree** for the reproduction, using the `using-git-worktrees` skill. This keeps the repro's throwaway state (build artifacts, scratch input files) out of your working tree.

b. **Build a minimal reproduction.** Based on the issue description and your codebase analysis, create the simplest scenario that triggers the bug — minimal input data, minimal invocation. Use a subagent to do this if it's involved: give it the issue context and error description, and have it construct and run the reproduction. It should:

- Set up the minimal state/inputs needed
- Run the command or code path that triggers the issue
- Capture the exact error output or incorrect behavior

c. **Document what you observed.** Before moving to planning, record:

- The exact steps that reproduce the issue
- The actual output/error (copied verbatim)
- The expected output/behavior
- Any differences from what the issue originally described

d. **Keep the worktree.** You'll reuse it in the verification step after the fix is implemented — don't clean it up until verification is complete.

If the bug **cannot be reproduced**, note that in the plan. It may mean the issue description is incomplete, the bug is environment-specific, or the underlying code has already changed. Ask the human how to proceed.

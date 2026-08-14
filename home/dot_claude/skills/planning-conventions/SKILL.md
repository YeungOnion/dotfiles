---
name: planning-conventions
description: Use when writing an implementation plan for work that has a real domain (not a toy/puzzle problem) — check domain-model impact, documentation impact, and test-coverage gaps before presenting the plan.
---

# Planning Conventions

## Domain Analysis

If the change affects a system with real domain concepts (not a toy or puzzle problem), the plan should identify the domain concepts, entities, and services affected. Use the `ddd` skill for guidance.

## Documentation Impact

Before presenting the plan, evaluate whether the change affects anything described in the project's design docs (`docs/`, `design/`, etc.) or its `.claude/skills/`. If so, include explicit plan steps to update those files. Common triggers: new domain concepts, changed CLI commands or flags, new extension/plugin patterns, modified architectural decisions, renamed types or methods referenced in skill examples.

## Test Coverage Assessment

Evaluate whether the change needs test coverage beyond what exists, in two categories:

- **User-facing behavior tests** — verify commands, flags, APIs, and output from a user's perspective.
- **Adversarial/robustness tests** — verify behavior under edge conditions: concurrency, resource exhaustion, security boundaries, state corruption, process lifecycle.

Assess:

- If the change **is purely internal** (refactors, internal API changes) and already covered by existing unit/integration tests → no action needed. State this when presenting the plan.
- If the change **affects user-facing behavior** and no existing test covers it → flag this to the human.
- If the change **affects robustness or edge-case behavior** and no existing adversarial test covers it → flag this to the human.
- If the human agrees a gap exists, either add the test as a plan step or note it as follow-up work — don't silently drop it.

Include the assessment findings when presenting the plan to the human.

## User-Facing Documentation Assessment

If the project maintains user-facing docs (README, `docs/`, a manual/handbook), evaluate whether this change requires updates there:

- If the change **is purely internal** with no user-visible behavior change → no docs action needed. State this when presenting the plan.
- If the change **adds a new user-facing feature** (new command, new flag, new pattern, new config option) and no existing doc covers it → flag this to the human.
- If the change **modifies existing user-facing behavior** (changed output, renamed flags, altered config schema, changed defaults) and an existing doc describes the old behavior → flag the stale doc to the human.
- If the change **deprecates or removes** a documented feature → flag the doc that needs updating or removal.

Include documentation assessment findings when presenting the plan to the human.

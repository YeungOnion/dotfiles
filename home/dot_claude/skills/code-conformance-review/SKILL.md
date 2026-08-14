---
name: code-conformance-review
description: Use when checking implemented code against an approved plan — verifying every planned step landed, flagging unplanned changes, and confirming testing and risk mitigations match what was planned.
---

# Code Conformance Review

Compare the implemented code against the approved plan. The plan is a guide, not a rigid contract — deviations are expected. What matters is understanding and documenting **why** the code differs.

For each plan step, verify whether the code implements it, then check for unplanned changes not covered by the plan.

## Plan Completeness

Was every planned step implemented? For each step in the plan:

- Read the files listed in the step and verify the described change exists
- If a step is missing or incomplete, record the status and ask why
- A step may have been intentionally skipped — that's fine if justified

## Scope Adherence

Are there changes beyond what the plan specified?

- Diff the branch against the base and identify files changed that aren't in any plan step
- Unplanned changes are recorded as `added` steps with status `added`
- Refactoring adjacent code, fixing unrelated bugs, or adding unplanned features all count as scope deviations that need justification

## File Coverage

Were the planned files touched? Were unexpected files changed?

- Cross-reference the plan's file lists against the actual diff
- Files in the plan but not in the diff suggest missing implementation
- Files in the diff but not in the plan suggest unplanned changes

## Domain Conformance

Does the implementation match the plan's domain analysis (see the `ddd` skill if one was used to produce it)?

- If the plan specified domain boundaries, verify the code respects them
- New types, services, or repositories should align with that analysis
- Deviations should be justified — sometimes implementation reveals the planned domain model was wrong

## Testing Coverage

Does test coverage match the planned testing strategy?

- Verify that the planned test types (unit, integration, end-to-end) were written
- Check that edge cases identified in the plan have corresponding tests
- Missing tests are a deviation that needs justification

## Risk Mitigation

Were the identified risks and challenges properly addressed?

- For each risk listed in the plan, verify the implementation handles it
- Unaddressed risks need justification — sometimes a risk turned out to be irrelevant

## Convention Compliance

Does the code follow project patterns from the project's design docs?

- Verify naming conventions, file placement, and architectural patterns
- Check that CLAUDE.md/AGENTS.md conventions were followed
- This dimension catches implementation quality issues the plan couldn't predict

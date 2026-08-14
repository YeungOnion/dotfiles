---
name: ddd
description: Use when a plan, PR, or ADR touches a system with real domain concepts — entities, business rules, subsystem boundaries — as opposed to a toy or puzzle problem with no domain model.
---

# DDD Analysis

## Core Analysis

For any plan, PR, or ADR touching a system with real domain concepts:

- **Identify affected domain objects**: which entities, value objects, aggregates, and domain services does this change touch? Name them explicitly — don't leave them implicit in the diff.
- **Check ubiquitous-language consistency**: does the plan/PR use the same terms as the domain model and existing code, or does it introduce a synonym for something that already has a name? Language drift here is a defect, not style.
- **Check bounded-context boundaries**: does the change cross a boundary between subsystems? If so, classify the relationship (Partnership, Customer-Supplier, Conformist, Anticorruption Layer, Open Host Service, Published Language, Separate Ways) and check the change respects it — e.g. a Conformist relationship shouldn't suddenly demand upstream changes.
- **Check aggregate consistency boundaries**: does the change assume transactional consistency across what should be separate aggregates?

Ground these checks in Evans' *Domain-Driven Design* (Ubiquitous Language, Bounded Context, Aggregate) and Vernon's *Implementing Domain-Driven Design* (context-mapping relationship patterns).

### Example

Plan: "Add a `retryCount` field to `Order` and have the billing service poll it to decide when to re-attempt a charge."

- **Affected domain objects**: `Order` (aggregate) gains state; `BillingService` (domain service) gains a read dependency on it.
- **Ubiquitous-language check**: the codebase already has "attempt" as the term for a charge try (`ChargeAttempt` entity exists elsewhere) — `retryCount` introduces a second word for the same concept. Flag it: reuse `attemptCount` or reference `ChargeAttempt` directly instead of a bare counter.
- **Bounded-context check**: `Order` lives in the Ordering context, `BillingService` in the Billing context. Polling `Order` state from Billing is a Conformist-style dependency in the wrong direction — Billing should own retry state, and Ordering should publish charge-relevant events instead. Flag as a boundary violation, not just a style note.
- **Aggregate consistency check**: does the poll read `Order.retryCount` transactionally with the charge attempt, or can they drift under concurrent updates? If drift is possible, the plan needs to say whether that's acceptable.

## Multi-Persona Review

For higher-stakes reviews (architectural plans, ADR proposal/rejection, PRs with significant domain impact), escalate beyond single-voice analysis by running the change past predefined domain and engineering personas who can challenge, accept, or offer middle-ground language. Any invoking agent — human or supervisor — can request this; it isn't gated behind human-only invocation.

See `references/persona-review.md` for roster discovery, persona file schema, execution modes (independent / sequential / async-debate), and the synthesis output format.

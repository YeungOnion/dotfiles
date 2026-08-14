---
name: pragmatic-fp
description: principles and guidelines to use FP patterns
---

# Functional Composition and Effect Isolation Guidelines

## Core Principle

Prefer explicit dataflow over implicit control flow.
*   **Do:** Transform values, resolve identities, interpret declarative operations, or execute isolated effects.
*   **Avoid:** Functions that simultaneously orchestrate sequencing, mutate shared state, perform IO, shape output, and compute derived values.

## Architectural Preferences

### Pipeline Over Orchestration
Prefer explicit sequential pipelines: `Input -> Normalize -> Resolve -> Compute -> Persist -> Project`.
Avoid deeply nested imperative control flow where effects, branching, mutation, aggregation, and serialization interleave.

### Isolate Effects at Explicit Boundaries
Effectful operations (DB queries, FS access, network requests, subprocesses, logging, time/randomness) must handle exactly one concern, return explicit values, and avoid hidden mutation or orchestration.
**They must accept all required data explicitly as arguments rather than capturing variables via closures.**
*   **Prefer:** `fetch_entity(repo, normalized_input) -> ResolvedEntity`
*   **Avoid:** `fetch_entity_and_update_stats_and_append_output(...)` or relying on ambient scope.

### Keep Pure Computations Pure
Pure functions must depend only on explicit inputs and return transformed values.
Extract logic like normalization, deduplication, aggregation, scoring, projection, shaping, and validation into pure functions that touch no ambient state or IO.
Define these API in terms of contracts from the inside out.

### Explicit Intermediate Representations
Use named, immutable structures for normalized values, resolved identities, computed relationships, and operation plans.
Avoid loosely-typed dictionaries or anonymous tuple threading.
*   **Prefer:** `NormalizedRecord`, `ResolvedNode`, or `OperationPlan` over dictionaries.

### Semantic Decomposition
Do not extract helpers solely to shorten code length.
Each function must represent one semantic transformation, one strict effect boundary, or one interpretation stage.


### Avoid Hidden Control Flow and Shared State
Avoid architectures dominated by callbacks, mutable closures, implicit event propagation, observer chains, or threaded mutation.
Prefer explicit sequencing, immutable accumulators, reductions/folds, and returned aggregates.

### Declarative Operations
For complex workflows, represent operations as explicit data structures (e.g., `DomainCommand`, `InsertEntity`) before executing them.
Separating planning, interpretation, and execution improves testing, batching, and explainability.

## Nesting Heuristics

Deep nesting usually indicates interleaved effects/transformations or missing intermediate representations. Before introducing a nested block, verify if you are missing:
1. A pure intermediate representation.
2. A stricter effect boundary.
3. A distinct semantic transformation stage.
4. Separation of orchestration from execution.

## Preferred Code Shape

Top-level orchestration should read declaratively, describing only stages, sequencing, and dataflow. Business logic belongs inside the semantic transformations, not the orchestrator.

```python
normalized = normalize(input)
resolved = resolve(normalized)
derived = compute(resolved)
persisted = persist(derived)
outputs = project(persisted)

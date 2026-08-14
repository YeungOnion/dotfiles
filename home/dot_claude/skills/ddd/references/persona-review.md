# Multi-Persona Review

## Roster discovery

Look in this order, stop at the first hit:

1. `docs/**/persona*/` in the current repo
2. Top-level `CLAUDE.md` — check whether it indexes/points to where personas are defined
3. If `CLAUDE.md` points to another repo, or the invoker names one, fetch it with `gh repo view` / `gh api` — never guess a URL

If no roster is found, stop and ask rather than inventing personas. Fabricated stakeholders undermine the review — they aren't a fallback.

## Persona file schema

One persona per file:

```
name: <persona name>
role-type: domain | engineering
vocabulary: terms this persona insists on / rejects (ubiquitous-language anchors)
stance: what they typically challenge, accept outright, or are willing to compromise on
```

Most personas in practice are domain roles (e.g. claims adjuster, underwriter), not software-engineer-first roles — expect the roster to skew domain-heavy.

## Execution modes

Mode is requested by whichever agent invokes the review — human or supervising agent, not necessarily the end user. Ask which mode if unspecified.

- **Independent**: one subagent per persona, run in parallel, fully isolated from each other and from the other personas' output. Each returns a challenge / accept / middle-ground-offer stance with reasoning in that persona's own vocabulary.
- **Sequential**: personas run in a fixed order; each sees the prior personas' stated positions before responding, producing a debate chain.
- **Async debate**:
  1. **Independent round** — same as independent mode, fully isolated.
  2. **Share round** — all positions from the independent round are exposed to all personas.
  3. **Rebuttal round** — each persona, now seeing every other persona's stance, may revise their position or hold it.
  4. **Synthesis** — see below.

## Synthesis

Regardless of mode, the invoking agent (not a persona) synthesizes the final positions into a single recommendation — accept / revise / reject — plus a dissent appendix that attributes specific objections to specific personas, and any middle-ground language a persona explicitly offered. Synthesis happens automatically once the mode's rounds complete; it does not wait on a separate human checkpoint.

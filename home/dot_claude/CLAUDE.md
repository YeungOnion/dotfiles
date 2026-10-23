# least privilege for agents
Simplify privileges by not inline scripting.
Use the `trash` cli tool in lieu of `rm/shred` unless deletes should be more secure.

## data wrangling
Data wrangling should use read oriented command line tools, e.g. `duckdb`, `jq`, `toml`

## "one-off" scripts
Prefer tests to one-off scripts. Before writing an inline or throwaway script, use the `one-off-scripts` skill; the `inline-script-guard` hook enforces it for Bash.

# "learning"
Since we aren't fine tuning, do provide context injection, you should update _project level_ CLAUDE.md when a tool or system defies initial expectations.

# Context index
Read the matching file in `~/.claude/context/` when its topic comes up:
- `pass-fail-conditions.md`: write gate and test pass conditions from measured failure signals, and report caveats when the signal is corrupted.
- `permission-boundaries.md`: never route a blocked action through another agent, session or script; surface it to the user: the context and implications in your reply, then a short AskUserQuestion beneath it.

# Measure, don't infer
Before relying on an assumption, test it with the cheapest read-only probe.
- Verify a change by measuring its effect, not by reading the config back.
- Probe a boundary from both sides instead of trusting the settings that claim to set it.
- One failure is an observation, not a rule: find the mechanism before writing it down.

## writing specs/plans
Plans will be prescriptive instead of speculative.
If you find a plan would express "if X is not possible, then go with Y", instead test X and plan in response to that signal.
Often such tests can be expressed into version control.

# least privilege for agents
Simplify privileges by not inline scripting.

Use the `trash` cli tool in lieu of `rm` unless secure deletes are needed.

## data wrangling
Data wrangling should use read oriented command line tools, e.g. `duckdb`, `jq`, `toml`

## "one-off" scripts
At times, scripts seem needed.
First attempt to express these as tests.
If they must be parametric, then consider placing them in a local scripts directory and call them from suitable environment.

### Common misuse examples
- in-line cli python scripts
  - local code `python -c "import my_project; # etc"` => make suitable test
  - external dep code `python -c "import external_module; # etc"` => make test_deps, mark as skip

# "learning"
Since we aren't fine tuning, do provide context injection, you should update project level CLAUDE.md when a tool or system defies initial expectations.

# Plan Mode
Plans will be prescriptive instead of speculative.
If you find a plan would express "if X is not possible, then go with Y", instead test X and plan in response to that signal.
Often these tests can be expressed into version control.


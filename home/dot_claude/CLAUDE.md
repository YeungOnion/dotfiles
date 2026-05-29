# "learning"
Since we aren't fine tuning, do provide context injection, you should update project level CLAUDE.md when a tool or system defies initial expectations.

# Plan Mode
Plans should be prescriptive instead of speculative.
If you find a plan would have "if X is not possible, then go with Y", instead test X and plan in response to that signal.
Often these tests can be expressed into version control.

# Tool calls and least privilege

## data manipulation
Never use `python -c` or `python3 -c` for one-off data wrangling.
Use cli tools for data processing,
- jq
- toml
- ast-grep
- duckdb, consider flags -cmd -c -readonly

## "small" scripts
Quick scripts written to validate expectations belong in tests instead.

### Common misuse examples
- in-line cli python scripts
  - local code `python -c "import my_project; # etc"` => make suitable test
  - external dep code `python -c "import external_module; # etc"` => make test_deps, mark as skip

# chezmoi dotfiles — AI working notes

## chezmoi state tracking for scripts

`run_onchange_` scripts are tracked in **`entryState`** (keyed by destination path
e.g. `/home/user/.chezmoiscripts/01-name.sh`) not only `scriptState`. Clearing
`scriptState` alone is insufficient to make these scripts appear in dry-run.

To get a fresh-machine dry-run without touching real state:
```bash
chezmoi apply --persistent-state /tmp/fresh-$$.boltdb --dry-run --verbose
```
Do NOT use `mktemp` to create the file path — `mktemp` creates an empty file (0 bytes)
which is not a valid BoltDB. Chezmoi silently falls back to the real state file when
`--persistent-state` points to an invalid file.

`chezmoi state delete-bucket` requires `--bucket <name>` (named flag, not positional).
Positional syntax fails silently when errors are suppressed with `2>/dev/null`.

## `make test-unit` writes to the real source tree

The fisher tests run `chezmoi add ~/.config/fish/functions` against the live home
and source. Any fish function edited in source but not yet applied is overwritten
with the deployed copy. `chezmoi apply` the edited target before running the suite.

The same tests also dirty `home/.chezmoiignore` (a duplicate `_chezmoi_add_test.fish`
line, plus fisher-block resyncs). Revert it with `git checkout -- home/.chezmoiignore`
after a run unless the fisher-block change is intended.

## chezmoi.test.toml

Contains only `[data]\n  java_home = ""` — just enough to satisfy `promptStringOnce`
without interactive prompts. Package lists come from `.chezmoidata.toml` (source tree).

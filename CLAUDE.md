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

## Test tiers: host tests are read-only

`make test-unit` runs on the live home and must not write to the source or
`~/.config`. A host test that ran `chezmoi add` once overwrote unapplied source
edits with deployed copies. Fresh-machine and mutating checks go in `tests/fish/container/`
(`make test-container`), which runs only via `make test-smoke` and guards on
`CHEZMOI_TEST_CONTAINER` plus `/.dockerenv`.

fishtape itself rewrites `~/.config/fish/fish_variables` (its counters are
universal vars) — an mtime-only change, not a test side effect.

## Read-only chezmoi queries for ignore state

- `chezmoi ignored` lists nothing for target-only files; it cannot answer
  "would `chezmoi add` skip this file".
- `chezmoi add --dry-run --verbose <paths>` prints `chezmoi: warning: ignoring <rel>`
  per ignored path and writes nothing. Pass `--no-pager` and `</dev/null`: a large
  diff for an unignored file otherwise blocks in the pager.
- fisher records each plugin's installed files in universal `_fisher_<plugin>_files`
  (paths start with a literal `~`). fish has no wildcard variable expansion, so
  enumerate with `set -Un | string match '_fisher_*_files'` and `$$var`.

## fisher is orchestrated by chezmoi

- Plugin list: `fish_plugins` in `home/.chezmoidata/fish.json`. `~/.config/fish/fish_plugins`
  is rendered from it. Change it with `mise run fish-plugin add|remove owner/repo`, not
  `fisher install` (the nudge prints the task usage).
- `run_onchange_after_06-fish-plugins` runs `fisher update` after deploy, then fails if
  any listed plugin is missing (`fisher update` exits 0 when one download fails).
  fisher compares names lowercased, so case is harmless; the entry's shape matters — a
  trailing slash or whitespace names a different plugin. Tests and `fish-plugin` enforce
  `owner/repo`.
- `.chezmoiignore` is a template: fisher-owned paths come from `_fisher_*_files` via
  `output "fish" "-c" ...`. `fish --no-config` does not load universal variables, so the
  template must use plain `fish -c`. Its output is filtered to lines starting with
  `.config/fish/`. If fish is on PATH but cannot start, `output` errors and every chezmoi
  command fails until fish is fixed.
- `.chezmoiremove` errors with `inconsistent state` while the source file still exists:
  delete the source file in the same change.
- Retiring a conf.d hook deletes the file but not functions already loaded in open
  shells. After rolling out the removal of `fisher_chezmoi_sync.fish`, `exec fish` (or
  close) every open shell: the old `_fisher_postexec_sync` fires on `fisher install|update|remove`
  and appends a `# fisher:begin` block to `home/.chezmoiignore`. The unit test
  "ignore template has no fisher:begin marker" detects it; undo with
  `git checkout -- home/.chezmoiignore`.

## chezmoi.test.toml

Contains only `[data]\n  java_home = ""` — just enough to satisfy `promptStringOnce`
without interactive prompts. Package lists, fish plugins and universals come from JSON in `home/.chezmoidata/` (source tree).

## Data tasks (mise-tasks/)

Hand-made changes that belong in chezmoi data go through repo-scoped mise tasks, so they
are repeatable: `fish-plugin add|remove`, `pkg add|remove <manager> <name>`,
`fish-var set|unset`. Run them from anywhere with `mise -C ~/.local/share/chezmoi run …`;
`--help` shows usage. Each edits JSON through `scripts/data-edit` (the only JSON mutator),
prints the diff, then applies (named targets or `--include=scripts`, never a bare apply).
`pkg remove` uninstalls with the package manager because script 02 only installs.
The `chezmoi_nudge` hook prints the matching task's usage after `brew|cargo|uv tool|fisher`
installs and removals, and `set -U`. It recognises only the kind of command and never
parses installer arguments.

Testing tasks:
- Point tasks at a temp copy with `DOTFILES_DATA_DIR` and skip applying with
  `DOTFILES_NO_APPLY=1`.
- mise prepends its own tool directories (chezmoi is a mise tool here) to PATH inside
  tasks, so a PATH stub never shadows chezmoi. Tasks read the command from
  `DOTFILES_CHEZMOI` (default `chezmoi`); inject a stub there.

## fish/fishtape gotchas

- `$a:$PATH` expands once per PATH element (PATH is a list). Build PATH values with
  `(string join : $a $PATH)`.
- fishtape drops a `@test` whose `"$(…)"` hits an unknown command: it prints neither
  `ok` nor `not ok`. Watch pass totals when a test's subject does not exist yet.

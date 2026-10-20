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
- Directory jumping is zoxide (initialized in `config.fish`, `--cmd z`), not jethrokuan/z: z
  rewrote its data on every `cd` without checking the write. zoxide history is per
  machine (`~/.local/share/zoxide`); on a new machine with old z data, import it once
  with `_Z_DATA=~/.local/share/z/data zoxide import z` (0.10 takes no path argument and
  reads `$_Z_DATA`; `--merge` if zoxide already has history).

## chezmoi.test.toml

Contains `[data]` with `java_home = ""` and `cc_host_user = ""`, plus a `[data.brew_tap_trust]` answer for every tap in
`brew_tap_packages` — just enough to satisfy the `prompt*Once` calls without interactive
prompts. Package lists, fish plugins and universals come from JSON in `home/.chezmoidata/`
(source tree). It has no `fish_paths_local`, so the container renders only the shared PATH
entries.

A real `chezmoi init` with no TTY and no stored answer fails (`could not open a new TTY`),
while `execute-template --init` silently renders `false`; only the test in
`brew_taps_test.fish` catches a missing answer before the Docker build does.

## Local config changes need `chezmoi init` on each machine

The local `~/.config/chezmoi/chezmoi.toml` is rendered from `.chezmoi.toml.tmpl` only by
`chezmoi init`. After pulling a change to that template, or a new tap in
`brew_tap_packages`, run `chezmoi init` once on each machine (it prompts only for unanswered
values and keeps the rest).
- A template change makes every chezmoi command warn "config file template has changed"
  (which fails `fish_paths_test`'s diff check) until init reruns.
- A new tap does not warn: until init asks, script 02 skips its formulas with a ⏭ line.

## ssh config: shared hosts in the repo, the rest in config.local

The repo is public. `~/.ssh/config` is a template whose host users come from `prompt*Once`
answers (`cc_host_user`; blank renders no entry), so usernames stay in the local
chezmoi config. Its first line is `Include config.local`: ssh takes the first value it
reads, so `~/.ssh/config.local` overrides repo entries, and an `Include` inside a `Host`
block would apply only to that host. `.chezmoiignore` ignores `.ssh/*` except `config`, so
`chezmoi add` refuses `config.local` and keys (`ssh_config_test.fish`).

## fish version: Homebrew 4.x only

fish comes from Homebrew (`fish` in `brew_packages`), at
`/home/linuxbrew/.linuxbrew/bin/fish`, which is also the login shell. Do not
hard-code a fish path elsewhere: Windows Terminal, WezTerm (no `default_prog`; it
runs the passwd login shell as `-fish`) and tmux all start the login shell.
- Two fish versions sharing `~/.config/fish` fight over universals: 4.3+ stops
  setting `fish_color_*` and moves `fish_key_bindings` into `conf.d/fish_frozen_*`,
  so 3.x shells lost all colors, and `__fish_initialized` flipped between them.
  Key bindings use 4.x notation (`ctrl-r`); 3.x binds that as literal characters.
- systemd units do not get the login PATH: `terminal-theme-poll.service` runs fish
  and `reg.exe` by absolute path (no PATH rendered at apply time, which once
  rendered `.` for reg.exe).

## fish startup layout and PATH entries

Follows fish's documented model: `conf.d/` snippets run first (in name order), then
`config.fish` runs last as the main file.
- `config.fish.tmpl` owns setup in line order: environment (`RUSTUP_HOME`, `CARGO_HOME`,
  `GOPATH`, …) → Nix's own `nix-daemon.fish` (guarded; before Homebrew so brew's tools win
  overlaps) → Homebrew `shellenv` (prefix per OS) → `fish_add_path --global --path` →
  interactive settings → tool hooks (mise, direnv, zoxide), each `command -q`-guarded and
  silent when missing.
- `conf.d/` holds only self-contained snippets (nudge, terminal theme, installer env files,
  fisher plugins). No numeric-prefix ordering tricks.
- PATH is declarative: `--global --path` changes the session only, so nothing is saved to
  universal `fish_user_paths`, and removing an entry from data removes it from PATH. (Plain
  `fish_add_path` in a config file writes universal state that is never cleaned up.)
  Universal `fish_user_paths` should stay unset; if an installer or a one-off
  `fish_add_path` re-creates it, move the entries into data and `set -eU fish_user_paths`
  (fish's `--on-variable` handler drops them from PATH in open shells).
- `tests/fish/startup_test.fish` checks the order and a fresh shell (no `fish_variables`,
  bare PATH).

The `fish_add_path` line renders two lists:
- shared: `fish_paths` in `home/.chezmoidata/fish.json` — schema-validated (`/abs`, `~/rel`
  or `$VAR/rel`, plain path characters), rendered unquoted so `~`/`$VAR` expand;
- machine-only: `fish_paths_local` in the local `~/.config/chezmoi/chezmoi.toml` (never in
  the repo; `.chezmoi.toml.tmpl` carries it across `chezmoi init`), rendered single-quoted.
When an installer appends `fish_add_path …` to `~/.config/fish/config.fish`, move that path
into `fish_paths_local` (`chezmoi edit-config`) instead of `chezmoi add`-ing the file.

## Data tasks (mise-tasks/)

Hand-made changes that belong in chezmoi data go through repo-scoped mise tasks, so they
are repeatable: `fish-plugin add|remove`, `pkg add|remove <manager> <name>`,
`fish-var set|unset`. Run them from anywhere with `mise -C ~/.local/share/chezmoi run …`;
`--help` shows usage. Each edits JSON through `scripts/data-edit` (the only JSON mutator),
which validates the whole result against `scripts/data-schema.jq` (unique entries, plugin
`owner/repo` unique ignoring case, safe package names, valid variable names) before
replacing the file; it then prints the diff, then applies (named targets or `--include=scripts`, never a bare apply).
`pkg remove` uninstalls with the package manager because script 02 only installs.
`pkg add brew-tap owner/tap/formula` records a tap formula and runs `chezmoi init` (prompts
once for an unanswered tap) before applying; answering no keeps the formula in data, but
script 02 skips it with a ⏭ line. To change an answer later, edit `[data.brew_tap_trust]`
with `chezmoi edit-config`. Tap formulas never go in the other brew lists (the schema
rejects a `/` there): `brew install owner/tap/formula` taps on its own, skipping the prompt.
The `chezmoi_nudge` hook prints the matching task's usage after `brew|cargo|uv tool|fisher`
installs and removals, and `set -U`. It recognises only the kind of command and never
parses installer arguments.

Testing tasks:
- Point tasks at a temp copy with `DOTFILES_DATA_DIR` and skip applying with
  `DOTFILES_NO_APPLY=1`.
- mise prepends its own tool directories (chezmoi is a mise tool here) to PATH inside
  tasks, so a PATH stub never shadows chezmoi. Tasks read the command from
  `DOTFILES_CHEZMOI` (default `chezmoi`); inject a stub there.
- fish loads `config.fish` and `conf.d/` even non-interactively, and that config puts
  linuxbrew first on PATH, so a PATH stub for `brew` lost to the real one (a test ran a
  real `brew uninstall bat`; brew refused only because of a dependent). Tasks and
  `scripts/data-edit` therefore use `#!/usr/bin/env -S fish --no-config`, and any test
  that can reach a real package manager first asserts the stub resolves inside
  `mise exec -- fish --no-config` and skips otherwise. Do not use `--no-config` where
  universal variables are needed (it hides them): `fish-var` erases via plain `fish -c`.

## Package names that are not what they seem

- crates.io `vector` is an unrelated library (stainless-steel/vector), not vectordotdev's
  vector. Before adding a cargo binary, check the crate's repository on crates.io.
- `vectordotdev/brew` only ships macOS binaries; on Linux its formula is HEAD-only (a full
  Rust build), and homebrew-core has no `vector`. vector is a manual install per machine.

## fish/fishtape gotchas

- `trash` (cargo, 1.0.0) follows symlinks: on a dangling one it reports
  `No such file or directory`. A dangling link holds no data; `unlink` it.
- `$a:$PATH` expands once per PATH element (PATH is a list). Build PATH values with
  `(string join : $a $PATH)`.
- fishtape drops a `@test` whose `"$(…)"` hits an unknown command: it prints neither
  `ok` nor `not ok`. Watch pass totals when a test's subject does not exist yet.

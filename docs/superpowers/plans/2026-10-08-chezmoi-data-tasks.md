# chezmoi data tasks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every hand-made change that belongs in chezmoi data (packages, fish plugins, fish universal variables) repeatable through a repo-scoped mise task, and close the deferred review minors from the fisher plan.

**Architecture:** Chezmoi data moves from `home/.chezmoidata.toml` to JSON files in `home/.chezmoidata/` so it can be edited mechanically with `jq`. One editing script, `scripts/data-edit`, owns all JSON mutation. Three mise file tasks in `mise-tasks/` (`fish-plugin`, `pkg`, `fish-var`) validate input, call `scripts/data-edit`, then apply immediately. The `chezmoi_nudge` hook maps a typed command (`brew install x`, `fisher install x`, `set -U X v`, …) to the exact `mise -C <repo> run …` invocation that records it.

**Tech Stack:** fish 4.8, jq 1.7, mise 2026.3 file tasks with `#USAGE` specs, chezmoi v2.69, fishtape, Docker BuildKit

**Spec:** the Background section below (decisions agreed in session 2026-10-07/08). No separate spec file.

## Background

Decisions made by the user (do not re-litigate):

- Move chezmoi data to JSON; `jq` is the editing tool.
- Tasks in scope: `fish-plugin`, `pkg` (package lists), `fish-var` (fish universal variables). Completions regeneration is out of scope.
- Tasks **edit and apply immediately**; the user commits.
- Tasks are repo-scoped (mise tasks), not global fish functions. The nudge prints the runnable usage, which makes item 5 of the fisher review (silent removal of hand-installed plugins) moot.
- Review minors to fix: 1 (filter ignore output), 2 (CLAUDE.md spelling correction + shape validation), 3 (script 06 bootstrap), 6 (no-fish test inspects PATH directly), 7 (vacuous tests), 9 (`set -Un` everywhere). Minor 8 (Docker rebuild on plugin change) stays.

Facts verified before writing this plan:

- chezmoi merges JSON files in a `.chezmoidata/` directory with `.chezmoidata.toml` (scratch source probe returned keys from both).
- `toml get home/.chezmoidata.toml .` prints the whole file as JSON with every key: `brew_packages`, `brew_packages_darwin`, `brew_packages_linux`, `cargo_binaries`, `cargo_plugins`, `fish_plugins`, `fish_universal`, `uv_packages`.
- `toml-cli` 0.2.3 cannot append to arrays or write in place.
- mise 2026.3 runs an executable file in `mise-tasks/` as a task, exposes `#USAGE arg "<x>"` values as `$usage_x`, prints generated usage for `--help`, and `mise -C <dir> run …` works from any cwd. The repo is already mise-trusted.
- `chezmoi apply --include=scripts` re-runs only scripts whose rendered content changed: a package-list change re-runs 02, a plugin change re-runs 06, a universal-variable change re-runs 04.
- Current data references outside templates: `Dockerfile` lines 8, 33-34, 49, 53-54; `CLAUDE.md` lines 44, 63; `chezmoi_nudge.fish` lines 26, 29; test labels in `fisher_chezmoi_test.fish:30`, `container/fresh_install_test.fish:15`, `chezmoi_nudge_test.fish:67-73`.
- Host memory: `~/.config/fish/config.fish` carries untracked MotherDuck drift. Never run a bare `chezmoi apply` in this plan; use named targets or `--include=scripts`.

## Global Constraints

- Commit directly on `main`, matching repo history. Conventional-commit subjects. End every commit message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Do not push; pushing is the user's call at the end.
- No script filenames in `Makefile` or `Dockerfile`.
- Host tier (`make test-unit`) is read-only against the live home and source. Task tests point the tasks at a temp copy via `DOTFILES_DATA_DIR` and set `DOTFILES_NO_APPLY=1`.
- JSON files are written by `jq` with its default 2-space indent and a trailing newline, always via a temp file in the same directory followed by `mv`.
- Every fallible command in tasks and scripts is followed by `or exit $status` / `or return`. fish has no errexit.
- Never run a bare `chezmoi apply`; named targets or `--include=scripts` only.
- Use `trash`, not `rm`, in shell steps run by the executor.

## Review Focus

1. **A task fails halfway (apply or uninstall fails after the JSON edit).** The data is already changed; the user must see a non-zero exit and the diff. Tasks print `git -C <repo> diff --stat home/.chezmoidata` before applying, so the edit is visible even when apply fails. Test: Task 3 `apply failure exits non-zero` (stubbed `chezmoi` on PATH).
2. **Typo in a list name or manager (`pkg add brw x`).** Must fail before touching data. Tests in Task 4 (`unknown manager fails`, `data unchanged after unknown manager`).
3. **Adding an entry that already exists / removing one that doesn't.** Add is a no-op with exit 0 and no apply; remove of an absent entry exits 1. Tests in Task 2.
4. **Commands that look like installs but change something else (`cargo remove serde` edits Cargo.toml).** The nudge must stay silent. Test in Task 4 (`cargo remove … suggests nothing`). The nudge recognises only the kind of command and never parses arguments, so it cannot mis-name a package.
5. **Stray stdout from fish config while rendering `.chezmoiignore`.** Must not become an ignore pattern. Test in Task 6 with a temp `conf.d` that prints `*`.

---

### Task 1: Move chezmoi data to JSON

**Files:**
- Create: `home/.chezmoidata/packages.json`, `home/.chezmoidata/fish.json`
- Delete: `home/.chezmoidata.toml`
- Modify: `Dockerfile` (base and packages stages copy the directory), `CLAUDE.md` (lines 44, 63)
- Test: `tests/fish/chezmoi_data_test.fish` (new), `Makefile` (`test-unit` list)

**Interfaces:**
- Produces: `home/.chezmoidata/packages.json` keys `brew_packages`, `brew_packages_linux`, `brew_packages_darwin`, `cargo_plugins`, `cargo_binaries`, `uv_packages` (arrays of strings). `home/.chezmoidata/fish.json` keys `fish_plugins` (array of `owner/repo` strings) and `fish_universal` (object of string→string). Template-visible names are unchanged.

- [ ] **Step 1: Write the failing test**

Create `tests/fish/chezmoi_data_test.fish`:

```fish
#!/usr/bin/env fish
# chezmoi data lives in JSON under home/.chezmoidata/ so tasks can edit it with jq
# Run: fishtape tests/fish/chezmoi_data_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _data $_repo_root/home/.chezmoidata

@echo "data files"

@test "no TOML data file" \
    (test -e $_repo_root/home/.chezmoidata.toml && echo yes || echo no) = no

@test "packages.json is valid JSON" \
    (jq -e . $_data/packages.json >/dev/null 2>&1 && echo yes || echo no) = yes

@test "fish.json is valid JSON" \
    (jq -e . $_data/fish.json >/dev/null 2>&1 && echo yes || echo no) = yes

@echo "data reaches templates"

for key in brew_packages brew_packages_linux brew_packages_darwin cargo_plugins cargo_binaries uv_packages fish_plugins
    @test "$key renders as a list" \
        (chezmoi execute-template "{{ kindOf .$key }}" 2>&1) = slice
end

@test "fish_universal renders as a map" \
    (chezmoi execute-template '{{ kindOf .fish_universal }}' 2>&1) = map

@echo "fish_plugins entries have fisher's owner/repo shape"

# fisher parses fish_plugins with ^[^\s]+$ and compares lowercased names: case is
# harmless, a trailing slash or whitespace makes a different (missing) plugin
for p in (jq -r '.fish_plugins[]' $_data/fish.json 2>/dev/null)
    @test "$p is owner/repo" \
        (string match -qr '^[^/\s]+/[^/\s]+(@\S+)?$' -- $p && echo yes || echo no) = yes
end
```

Add `tests/fish/chezmoi_data_test.fish` to the `test-unit` recipe in `Makefile`, after `tests/fish/scratch_test.fish` (keep the `\` continuation style).

- [ ] **Step 2: Run to verify it fails**

Run: `cd ~/.local/share/chezmoi && fish -c 'fishtape tests/fish/chezmoi_data_test.fish' 2>&1 | rg '^not ok'`
Expected: `no TOML data file`, `packages.json is valid JSON`, `fish.json is valid JSON` fail. The template-kind tests pass now (data still comes from TOML) and must still pass after Step 3. No per-plugin shape tests run yet (file missing), which is why the JSON-validity tests exist.

- [ ] **Step 3: Convert**

```bash
cd ~/.local/share/chezmoi
mkdir -p home/.chezmoidata
toml get home/.chezmoidata.toml . | jq '{brew_packages, brew_packages_linux, brew_packages_darwin, cargo_plugins, cargo_binaries, uv_packages}' > home/.chezmoidata/packages.json
toml get home/.chezmoidata.toml . | jq '{fish_plugins, fish_universal}' > home/.chezmoidata/fish.json
git rm -q home/.chezmoidata.toml
git add home/.chezmoidata
```

- [ ] **Step 4: Rendered output must be byte-identical**

```bash
chezmoi status </dev/null
```
Expected: only `MM .config/fish/config.fish` (known drift). No script appears as `R`: identical rendered scripts mean the move changed nothing a machine would run.

- [ ] **Step 5: Dockerfile copies the directory**

In `Dockerfile`, replace both occurrences (base stage and packages stage) of
```
COPY --chown=testuser:testuser home/.chezmoidata.toml \
    /home/testuser/.local/share/chezmoi/home/.chezmoidata.toml
```
with
```
COPY --chown=testuser:testuser home/.chezmoidata \
    /home/testuser/.local/share/chezmoi/home/.chezmoidata
```
and in the two `# Invalidated by:` comments replace `.chezmoidata.toml` with `.chezmoidata/`.

- [ ] **Step 6: CLAUDE.md references**

- Line 44: replace `` `fish_plugins` in `.chezmoidata.toml` `` with `` `fish_plugins` in `home/.chezmoidata/fish.json` ``.
- Line 63: replace `` Package lists come from `.chezmoidata.toml` (source tree). `` with `` Package lists, fish plugins and universals come from JSON in `home/.chezmoidata/` (source tree). ``

- [ ] **Step 7: Run tests and commit**

```bash
make test-unit 2>&1 | tail -3
git add Dockerfile CLAUDE.md Makefile tests/fish/chezmoi_data_test.fish
git commit -m "refactor(chezmoi): move data to JSON under .chezmoidata/

toml-cli cannot append to arrays or write in place; JSON lets tasks edit
lists with jq. Template-visible keys are unchanged, so rendered scripts
are byte-identical.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
Expected: `# ok`.

---

### Task 2: `scripts/data-edit`, the single JSON mutator

**Files:**
- Create: `scripts/data-edit` (executable fish script)
- Test: `tests/fish/data_edit_test.fish` (new), `Makefile` (`test-unit` list)

**Interfaces:**
- Produces: `scripts/data-edit <file> list-add <key> <value>` · `list-remove <key> <value>` · `map-set <key> <name> <value>` · `map-unset <key> <name>`.
  - Exit 0 and file rewritten on change. `list-add` of a present value: prints `already listed: <value>` to stderr, exit 0, file untouched (mtime unchanged).
  - Exit 1, file untouched: unknown operation, missing key, wrong arity, `list-remove` of an absent value, `map-unset` of an absent name.
  - Exit 2: usage error (fewer than 3 args).
  - Prints nothing on stdout.

- [ ] **Step 1: Write the failing tests**

Create `tests/fish/data_edit_test.fish`:

```fish
#!/usr/bin/env fish
# Tests for scripts/data-edit — runs only against temp JSON files
# Run: fishtape tests/fish/data_edit_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _edit $_repo_root/scripts/data-edit

set -g _fixtures
function _fixture
    set -l f (mktemp --suffix .json)
    set -ga _fixtures $f
    echo '{"pkgs": ["a", "b"], "vars": {"X": "1"}}' | jq . > $f
    echo $f
end

@echo "list-add"

set -l f (_fixture)
@test "list-add appends a new value" \
    ($_edit $f list-add pkgs c; and jq -c .pkgs $f) = '["a","b","c"]'

set -l f (_fixture)
set -l before (stat -c %Y.%s $f)
@test "list-add of a present value exits 0" \
    ($_edit $f list-add pkgs a 2>/dev/null; echo $status) = 0
@test "list-add of a present value leaves the file untouched" \
    (stat -c %Y.%s $f) = $before

set -l f (_fixture)
@test "list-add on a missing key fails" \
    ($_edit $f list-add nope c 2>/dev/null; echo $status) = 1

@echo "list-remove"

set -l f (_fixture)
@test "list-remove drops the value" \
    ($_edit $f list-remove pkgs a; and jq -c .pkgs $f) = '["b"]'

set -l f (_fixture)
@test "list-remove of an absent value fails" \
    ($_edit $f list-remove pkgs zzz 2>/dev/null; echo $status) = 1
@test "failed list-remove leaves the file valid and unchanged" \
    (jq -c .pkgs $f) = '["a","b"]'

@echo "map-set / map-unset"

set -l f (_fixture)
@test "map-set adds a name" \
    ($_edit $f map-set vars Y 2; and jq -c .vars $f) = '{"X":"1","Y":"2"}'

set -l f (_fixture)
@test "map-set overwrites a name" \
    ($_edit $f map-set vars X 9; and jq -r .vars.X $f) = 9

set -l f (_fixture)
@test "map-unset removes a name" \
    ($_edit $f map-unset vars X; and jq -c .vars $f) = '{}'

set -l f (_fixture)
@test "map-unset of an absent name fails" \
    ($_edit $f map-unset vars NOPE 2>/dev/null; echo $status) = 1

@echo "errors"

set -l f (_fixture)
@test "unknown operation fails" \
    ($_edit $f frobnicate pkgs a 2>/dev/null; echo $status) = 1

@test "too few arguments is a usage error" \
    ($_edit 2>/dev/null; echo $status) = 2

@test "stdout stays empty on success" \
    (count ($_edit (_fixture) list-add pkgs z)) = 0

# only the files this test created
trash $_fixtures
```

Add `tests/fish/data_edit_test.fish` to `test-unit` in `Makefile`.

- [ ] **Step 2: Run to verify it fails**

Run: `fish -c 'fishtape tests/fish/data_edit_test.fish' 2>&1 | rg -c '^not ok'`
Expected: every test that expects a success or a specific status is `not ok` (script missing → fish status 127). Tests that only assert "file untouched" or "stdout empty" may pass vacuously now; they must still pass after Step 3.

- [ ] **Step 3: Implement**

Create `scripts/data-edit`, then `chmod +x scripts/data-edit`:

```fish
#!/usr/bin/env fish
# Single mutator for chezmoi JSON data (home/.chezmoidata/*.json).
# usage: data-edit <file> list-add|list-remove <key> <value>
#        data-edit <file> map-set <key> <name> <value>
#        data-edit <file> map-unset <key> <name>
# Writes via a temp file in the same directory, then mv. Prints nothing on stdout.

if test (count $argv) -lt 3
    echo "usage: data-edit <file> list-add|list-remove|map-set|map-unset <key> ..." >&2
    exit 2
end

set -l file $argv[1]
set -l op $argv[2]
set -l key $argv[3]
set -l rest $argv[4..-1]

jq -e --arg k $key 'has($k)' $file >/dev/null 2>&1
or begin
    echo "data-edit: key '$key' not in $file" >&2
    exit 1
end

set -l filter
set -l jqargs --arg k $key
switch $op
    case list-add
        test (count $rest) -eq 1; or begin; echo "data-edit: list-add takes one value" >&2; exit 1; end
        if jq -e --arg k $key --arg v $rest[1] '.[$k] | index($v) != null' $file >/dev/null
            echo "already listed: $rest[1]" >&2
            exit 0
        end
        set filter '.[$k] += [$v]'
        set -a jqargs --arg v $rest[1]
    case list-remove
        test (count $rest) -eq 1; or begin; echo "data-edit: list-remove takes one value" >&2; exit 1; end
        jq -e --arg k $key --arg v $rest[1] '.[$k] | index($v) != null' $file >/dev/null
        or begin; echo "data-edit: '$rest[1]' not in $key" >&2; exit 1; end
        set filter '.[$k] -= [$v]'
        set -a jqargs --arg v $rest[1]
    case map-set
        test (count $rest) -eq 2; or begin; echo "data-edit: map-set takes a name and a value" >&2; exit 1; end
        set filter '.[$k][$n] = $v'
        set -a jqargs --arg n $rest[1] --arg v $rest[2]
    case map-unset
        test (count $rest) -eq 1; or begin; echo "data-edit: map-unset takes one name" >&2; exit 1; end
        jq -e --arg k $key --arg n $rest[1] '.[$k] | has($n)' $file >/dev/null
        or begin; echo "data-edit: '$rest[1]' not in $key" >&2; exit 1; end
        set filter 'del(.[$k][$n])'
        set -a jqargs --arg n $rest[1]
    case '*'
        echo "data-edit: unknown operation '$op'" >&2
        exit 1
end

set -l tmp (mktemp -p (path dirname $file) .data-edit.XXXXXX)
or exit 1
jq $jqargs $filter $file > $tmp
or begin; command rm -f $tmp; exit 1; end
mv $tmp $file
```

- [ ] **Step 4: Run tests and commit**

```bash
make test-unit 2>&1 | tail -3
git add scripts/data-edit tests/fish/data_edit_test.fish Makefile
git commit -m "feat(scripts): data-edit, the single jq mutator for chezmoi JSON data

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
Expected: `# ok`.

---

### Task 3: `fish-plugin` task

**Files:**
- Create: `mise-tasks/fish-plugin` (executable fish script)
- Test: `tests/fish/mise_tasks_test.fish` (new), `Makefile` (`test-unit` list)

**Interfaces:**
- Consumes: `scripts/data-edit` (Task 2), `home/.chezmoidata/fish.json` key `fish_plugins` (Task 1).
- Produces: `mise run fish-plugin add|remove <owner/repo>`. Env: `DOTFILES_DATA_DIR` (default `<repo>/home/.chezmoidata`), `DOTFILES_NO_APPLY=1` skips apply. Exit 1 before any edit on bad action or shape. Later tasks reuse the same env names and the same "edit → diff → apply" order.

- [ ] **Step 1: Write the failing tests**

Create `tests/fish/mise_tasks_test.fish`:

```fish
#!/usr/bin/env fish
# Tests for mise-tasks/* — tasks are pointed at a temp copy of the data and never apply.
# Run: fishtape tests/fish/mise_tasks_test.fish

set -g _repo_root (path resolve (status dirname)/../..)

set -g _task_dirs
function _task_env
    set -l d (mktemp -d)
    set -ga _task_dirs $d
    cp $_repo_root/home/.chezmoidata/*.json $d/
    echo $d
end

function _run --description 'run a mise task against data dir $argv[1]'
    env DOTFILES_DATA_DIR=$argv[1] DOTFILES_NO_APPLY=1 mise -C $_repo_root run $argv[2..-1]
end

set -g _real_before (git -C $_repo_root status --porcelain home/.chezmoidata)

@echo "fish-plugin"

set -l d (_task_env)
@test "fish-plugin add records the plugin" \
    (_run $d fish-plugin add foo/bar >/dev/null 2>&1; jq -r '.fish_plugins[-1]' $d/fish.json) = foo/bar

set -l d (_task_env)
@test "fish-plugin remove drops the plugin" \
    (_run $d fish-plugin remove jethrokuan/z >/dev/null 2>&1; jq -r '.fish_plugins | index("jethrokuan/z")' $d/fish.json) = null

set -l d (_task_env)
@test "fish-plugin rejects a trailing slash" \
    (_run $d fish-plugin add foo/bar/ >/dev/null 2>&1; echo $status) = 1
@test "rejected plugin leaves data unchanged" \
    (cmp -s $d/fish.json $_repo_root/home/.chezmoidata/fish.json && echo same || echo changed) = same

set -l d (_task_env)
@test "fish-plugin rejects an unknown action" \
    (_run $d fish-plugin frob foo/bar >/dev/null 2>&1; echo $status) = 1

# apply failure must surface: a chezmoi that always fails is first on PATH
set -l d (_task_env)
set -l stub (mktemp -d)
printf '#!/bin/sh\nexit 7\n' > $stub/chezmoi; chmod +x $stub/chezmoi
# This test runs the task WITHOUT DOTFILES_NO_APPLY; only run it if the stub
# provably shadows the real chezmoi, so a real apply can never happen here.
set -l resolved (env PATH=$stub:$PATH sh -c 'command -v chezmoi')
@test "stub chezmoi shadows the real one" \
    $resolved = $stub/chezmoi
if test "$resolved" = $stub/chezmoi
    @test "apply failure exits non-zero" \
        (env PATH=$stub:$PATH DOTFILES_DATA_DIR=$d mise -C $_repo_root run fish-plugin add foo/bar >/dev/null 2>&1; test $status -ne 0; and echo yes; or echo no) = yes
end
trash $stub

@echo "real data untouched"

@test "repo data has no new changes" \
    "$(git -C $_repo_root status --porcelain home/.chezmoidata)" = "$_real_before"

# only the directories this test created
trash $_task_dirs
```

Add `tests/fish/mise_tasks_test.fish` to `test-unit` in `Makefile`.

- [ ] **Step 2: Run to verify it fails**

Run: `fish -c 'fishtape tests/fish/mise_tasks_test.fish' 2>&1 | rg '^(not )?ok'`
Expected `not ok`: `fish-plugin add records the plugin`, `fish-plugin remove drops the plugin`, `fish-plugin rejects a trailing slash` (status is mise's "no task" error, not 1), `fish-plugin rejects an unknown action`. `rejected plugin leaves data unchanged`, `apply failure exits non-zero` and `repo data has no new changes` pass vacuously now and must still pass after Step 3.

- [ ] **Step 3: Implement**

Create `mise-tasks/fish-plugin`, then `chmod +x mise-tasks/fish-plugin`:

```fish
#!/usr/bin/env fish
#MISE description="Add or remove a fisher plugin in chezmoi data, then install via chezmoi"
#USAGE arg "<action>" help="add or remove"
#USAGE arg "<plugin>" help="owner/repo, e.g. jorgebucaran/fishtape"

set -l repo (path resolve (status dirname)/..)
set -q DOTFILES_DATA_DIR; or set -l DOTFILES_DATA_DIR $repo/home/.chezmoidata
set -l action $usage_action
set -l plugin $usage_plugin

# fisher parses fish_plugins with ^[^\s]+$ and compares lowercased: a trailing
# slash or whitespace names a different plugin
string match -qr '^[^/\s]+/[^/\s]+(@\S+)?$' -- $plugin
or begin
    echo "fish-plugin: '$plugin' is not owner/repo" >&2
    exit 1
end

switch $action
    case add
        $repo/scripts/data-edit $DOTFILES_DATA_DIR/fish.json list-add fish_plugins $plugin
        or exit $status
    case remove
        $repo/scripts/data-edit $DOTFILES_DATA_DIR/fish.json list-remove fish_plugins $plugin
        or exit $status
    case '*'
        echo "fish-plugin: action must be add or remove, got '$action'" >&2
        exit 1
end

git -C $repo diff --stat -- home/.chezmoidata

set -q DOTFILES_NO_APPLY; and exit 0
# fish_plugins first, then script 06 (fisher update) re-runs because its content changed
chezmoi apply ~/.config/fish/fish_plugins
or exit $status
chezmoi apply --include=scripts
```

- [ ] **Step 4: Run tests**

Run: `make test-unit 2>&1 | tail -3` and `mise -C ~/.local/share/chezmoi run fish-plugin --help`
Expected: `# ok`; help shows `Usage: fish-plugin <action> <plugin>`.

- [ ] **Step 5: Real no-op check, then commit**

```bash
mise -C ~/.local/share/chezmoi run fish-plugin add jorgebucaran/fishtape; echo "exit=$?"
git status --short home/.chezmoidata
```
Expected: `already listed: jorgebucaran/fishtape`, `exit=0`, empty status. data-edit exits 0 on an already-listed value, so the task still runs both applies; they are no-ops because no data changed. Then:

```bash
git add mise-tasks/fish-plugin tests/fish/mise_tasks_test.fish Makefile
git commit -m "feat(mise): fish-plugin task records plugins in data and installs

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: `pkg` task and package nudges

**Files:**
- Create: `mise-tasks/pkg` (executable fish script)
- Modify (replace entirely): `home/private_dot_config/private_fish/conf.d/chezmoi_nudge.fish`
- Test: `tests/fish/mise_tasks_test.fish`, `tests/fish/chezmoi_nudge_test.fish`

**Interfaces:**
- Consumes: `scripts/data-edit`; `packages.json` keys from Task 1; env names from Task 3.
- Produces: `mise run pkg add|remove <manager> <name>`, managers → keys: `brew`→`brew_packages`, `brew-linux`→`brew_packages_linux`, `brew-darwin`→`brew_packages_darwin`, `cargo-plugin`→`cargo_plugins` (name without `cargo-` prefix), `cargo-bin`→`cargo_binaries`, `uv`→`uv_packages`. `add` applies scripts (02 re-runs); `remove` uninstalls that one package with its manager instead of applying. Nudge helper `__chezmoi_nudge_task <cmdline>` prints one usage line (no `mise -C` prefix) or returns 1; `__chezmoi_nudge` prefixes `chezmoi?: mise -C <repo> run `. Task 5 adds one `else if` branch to the same helper.

- [ ] **Step 1: Write the failing tests**

Append to `tests/fish/mise_tasks_test.fish`, before the `@echo "real data untouched"` line:

```fish
@echo "pkg"

set -l d (_task_env)
@test "pkg add brew records the package" \
    (_run $d pkg add brew cowsay >/dev/null 2>&1; jq -r '.brew_packages[-1]' $d/packages.json) = cowsay

set -l d (_task_env)
@test "pkg add cargo-plugin strips a cargo- prefix" \
    (_run $d pkg add cargo-plugin cargo-audit >/dev/null 2>&1; jq -r '.cargo_plugins[-1]' $d/packages.json) = audit

set -l d (_task_env)
@test "pkg remove uv drops the package" \
    (_run $d pkg remove uv jrnl >/dev/null 2>&1; jq -r '.uv_packages | index("jrnl")' $d/packages.json) = null

set -l d (_task_env)
@test "unknown manager fails" \
    (_run $d pkg add brw cowsay >/dev/null 2>&1; echo $status) = 1
@test "data unchanged after unknown manager" \
    (cmp -s $d/packages.json $_repo_root/home/.chezmoidata/packages.json && echo same || echo changed) = same
```

In `tests/fish/chezmoi_nudge_test.fish`:
The nudge recognises the *kind* of command and prints that task's usage line. It does not parse installer arguments (user decision: the nudge need not adapt to each installer).

- Replace the five "triggers nudge" tests under `Branch 1: install nudge triggers` (brew install, brew install with flags, cargo install, cargo binstall, uv tool install) with:

```fish
set -g _pkg_usage 'pkg add|remove <manager> <name>'

@test "brew install suggests pkg usage" \
    "$(__chezmoi_nudge_task 'brew install bat')" = $_pkg_usage

@test "brew install with flags suggests pkg usage" \
    "$(__chezmoi_nudge_task 'brew install --cask bat')" = $_pkg_usage

@test "cargo install suggests pkg usage" \
    "$(__chezmoi_nudge_task 'cargo install delta')" = $_pkg_usage

@test "cargo binstall suggests pkg usage" \
    "$(__chezmoi_nudge_task 'cargo binstall delta')" = $_pkg_usage

@test "uv tool install suggests pkg usage" \
    "$(__chezmoi_nudge_task 'uv tool install ruff')" = $_pkg_usage

@test "command prefix and leading spaces still match" \
    "$(__chezmoi_nudge_task '  command brew install bat')" = $_pkg_usage

@test "cargo remove (a Cargo.toml dependency) suggests nothing" \
    (count (__chezmoi_nudge_task 'cargo remove serde')) = 0

@test "nudge prints the runnable mise usage" \
    (string match -q 'chezmoi?: mise -C * run pkg add|remove <manager> <name>' (__chezmoi_nudge "brew install bat" 2>&1) && echo yes || echo no) = yes
```

- Replace `@test "brew uninstall does not trigger"` with:

```fish
@test "brew uninstall suggests pkg usage" \
    "$(__chezmoi_nudge_task 'brew uninstall bat')" = $_pkg_usage
```

- Replace the whole `Branch 3` section (header through end of file) with:

```fish
# ── Branch 3: fish plugins ────────────────────────────────────────────────────

@echo "Branch 3: fisher install/remove suggests the fish-plugin task"

set -g _plugin_usage 'fish-plugin add|remove <owner/repo>'

@test "fisher install suggests fish-plugin usage" \
    "$(__chezmoi_nudge_task 'fisher install foo/bar')" = $_plugin_usage

@test "fisher remove suggests fish-plugin usage" \
    "$(__chezmoi_nudge_task 'fisher remove foo/bar')" = $_plugin_usage

@test "fisher uninstall suggests fish-plugin usage" \
    "$(__chezmoi_nudge_task 'fisher uninstall foo/bar')" = $_plugin_usage

@test "fisher update suggests nothing" \
    (count (__chezmoi_nudge_task 'fisher update')) = 0

@test "fisher list suggests nothing" \
    (count (__chezmoi_nudge_task 'fisher list')) = 0
```

The existing "does not trigger" tests for `brew upgrade`, `cargo update`, `uv tool upgrade`, bare `uv install`, `apt install`, `pip install` stay unchanged (they check `chezmoi?:*` output of `__chezmoi_nudge`).

- [ ] **Step 2: Run to verify they fail**

Run: `fish -c 'fishtape tests/fish/mise_tasks_test.fish tests/fish/chezmoi_nudge_test.fish' 2>&1 | rg '^not ok'`
Expected `not ok`: the four `pkg` behaviour tests except `data unchanged after unknown manager` (vacuous now), and every `__chezmoi_nudge_task` test that expects output (function missing → empty output). The `count … = 0` tests pass vacuously now.

- [ ] **Step 3: Implement `pkg`**

Create `mise-tasks/pkg`, then `chmod +x mise-tasks/pkg`:

```fish
#!/usr/bin/env fish
#MISE description="Add or remove a package in chezmoi data, then install or uninstall it"
#USAGE arg "<action>" help="add or remove"
#USAGE arg "<manager>" help="brew, brew-linux, brew-darwin, cargo-plugin, cargo-bin or uv"
#USAGE arg "<name>" help="package name; cargo-plugin accepts cargo-x or x"

set -l repo (path resolve (status dirname)/..)
set -q DOTFILES_DATA_DIR; or set -l DOTFILES_DATA_DIR $repo/home/.chezmoidata
set -l action $usage_action
set -l name $usage_name

switch $usage_manager
    case brew
        set -f key brew_packages
        set -f uninstall brew uninstall $name
    case brew-linux
        set -f key brew_packages_linux
        set -f uninstall brew uninstall $name
    case brew-darwin
        set -f key brew_packages_darwin
        set -f uninstall brew uninstall $name
    case cargo-plugin
        set name (string replace -r '^cargo-' '' -- $name)
        set -f key cargo_plugins
        set -f uninstall cargo uninstall cargo-$name
    case cargo-bin
        set -f key cargo_binaries
        set -f uninstall cargo uninstall $name
    case uv
        set -f key uv_packages
        set -f uninstall uv tool uninstall $name
    case '*'
        echo "pkg: unknown manager '$usage_manager' (brew, brew-linux, brew-darwin, cargo-plugin, cargo-bin, uv)" >&2
        exit 1
end

switch $action
    case add
        $repo/scripts/data-edit $DOTFILES_DATA_DIR/packages.json list-add $key $name
        or exit $status
    case remove
        $repo/scripts/data-edit $DOTFILES_DATA_DIR/packages.json list-remove $key $name
        or exit $status
    case '*'
        echo "pkg: action must be add or remove, got '$action'" >&2
        exit 1
end

git -C $repo diff --stat -- home/.chezmoidata

set -q DOTFILES_NO_APPLY; and exit 0
if test $action = add
    # script 02 re-runs because the rendered package list changed
    chezmoi apply --include=scripts
else
    # 02 only installs; removing from data does not uninstall
    $uninstall
end
```

- [ ] **Step 4: Replace the nudge hook**

Replace the entire contents of `home/private_dot_config/private_fish/conf.d/chezmoi_nudge.fish`:

```fish
function __chezmoi_nudge --on-event fish_postexec
    set -l prev_status $status
    set -l cmd $argv[1]

    # Resolved lazily so chezmoi need not be in PATH at conf.d load time
    if not set -q __chezmoi_src
        command -q chezmoi && set -g __chezmoi_src (chezmoi source-path)
    end

    # Branches 1/3/4: hand-made changes that belong in chezmoi data → usage of the task that records them
    if test -n "$__chezmoi_src"
        set -l usage (__chezmoi_nudge_task $cmd)
        and echo "chezmoi?: mise -C "(path dirname $__chezmoi_src)" run $usage" >&2
    end

    # Branch 2: apply reminder — fires only when editor opened a chezmoiscript
    if string match -rq '^\s*(hx|vim|nvim|nano)\s' -- $cmd
        and string match -rq '\.chezmoiscripts/' -- $cmd
        if chezmoi status 2>/dev/null | string match -rq '^\s*R.*chezmoiscripts'
            echo "chezmoi: script changes pending → chezmoi apply" >&2
        end
    end

    return $prev_status
end

function __chezmoi_nudge_task --description 'Usage of the mise task that records a hand-made change in chezmoi data'
    # Lexical only, no subprocesses: recognise the kind of command, not its arguments.
    # Returns 1 (prints nothing) when no task applies.
    set -l cmd (string replace -r '^\s*(command\s+)?' '' -- $argv[1])
    if string match -rq '^brew\s+(install|uninstall|remove)\b|^cargo\s+(install|binstall|uninstall)\b|^uv\s+tool\s+(install|uninstall)\b' -- $cmd
        echo 'pkg add|remove <manager> <name>'
    else if string match -rq '^fisher\s+(install|remove|uninstall)\b' -- $cmd
        echo 'fish-plugin add|remove <owner/repo>'
    else
        return 1
    end
end
```

- [ ] **Step 5: Run tests, deploy, commit**

```bash
make test-unit 2>&1 | tail -3
mise -C ~/.local/share/chezmoi run pkg --help | head -3
chezmoi apply ~/.config/fish/conf.d/chezmoi_nudge.fish </dev/null
git add mise-tasks/pkg home/private_dot_config/private_fish/conf.d/chezmoi_nudge.fish tests/fish/mise_tasks_test.fish tests/fish/chezmoi_nudge_test.fish
git commit -m "feat(mise): pkg task; nudge prints the task that records an install

The install nudge pointed at .chezmoiscripts/, where package lists no
longer live. It now prints the usage of the task that records the
change, and recognises fisher uninstall, \`command\` prefixes and
leading spaces. It does not parse installer arguments.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
Expected: `# ok`; usage line `Usage: pkg <action> <manager> <name>`.

---

### Task 5: `fish-var` task and universal-variable nudge

**Files:**
- Create: `mise-tasks/fish-var` (executable fish script)
- Modify: `chezmoi_nudge.fish` (`__chezmoi_nudge_task`: add a `set -U` branch)
- Test: `tests/fish/mise_tasks_test.fish`, `tests/fish/chezmoi_nudge_test.fish`

**Interfaces:**
- Consumes: `scripts/data-edit` `map-set`/`map-unset`; `fish.json` key `fish_universal`; env names from Task 3; `__chezmoi_nudge_task` from Task 4.
- Produces: `mise run fish-var set <name> <value>` / `mise run fish-var unset <name>`. `set` applies scripts (04 re-runs `set -Ux` for all); `unset` also runs `fish -c 'set -eU <name>'`. Names must match `^[A-Za-z_][A-Za-z0-9_]*$`.

- [ ] **Step 1: Write the failing tests**

Append to `tests/fish/mise_tasks_test.fish`, before `@echo "real data untouched"`:

```fish
@echo "fish-var"

set -l d (_task_env)
@test "fish-var set records the variable" \
    (_run $d fish-var set FOO_THEME dark >/dev/null 2>&1; jq -r '.fish_universal.FOO_THEME' $d/fish.json) = dark

set -l d (_task_env)
@test "fish-var unset removes the variable" \
    (_run $d fish-var unset EDITOR >/dev/null 2>&1; jq -r '.fish_universal | has("EDITOR")' $d/fish.json) = false

set -l d (_task_env)
@test "fish-var rejects an invalid name" \
    (_run $d fish-var set 1BAD x >/dev/null 2>&1; echo $status) = 1

set -l d (_task_env)
@test "fish-var set without a value fails" \
    (_run $d fish-var set FOO >/dev/null 2>&1; echo $status) = 1
```

Append to `tests/fish/chezmoi_nudge_test.fish`:

```fish
# ── Branch 4: universal variables ─────────────────────────────────────────────

@echo "Branch 4: set -U suggests the fish-var task"

set -g _var_usage 'fish-var set|unset <name> [value]'

@test "set -U suggests fish-var usage" \
    "$(__chezmoi_nudge_task 'set -U FOO bar')" = $_var_usage

@test "set -Ux suggests fish-var usage" \
    "$(__chezmoi_nudge_task 'set -Ux FOO bar')" = $_var_usage

@test "set --universal suggests fish-var usage" \
    "$(__chezmoi_nudge_task 'set --universal FOO bar')" = $_var_usage

@test "set -eU suggests fish-var usage" \
    "$(__chezmoi_nudge_task 'set -eU FOO')" = $_var_usage

@test "set -g suggests nothing" \
    (count (__chezmoi_nudge_task 'set -g FOO bar')) = 0
```

- [ ] **Step 2: Run to verify they fail**

Run: `fish -c 'fishtape tests/fish/mise_tasks_test.fish tests/fish/chezmoi_nudge_test.fish' 2>&1 | rg '^not ok'`
Expected `not ok`: the four `fish-var` tests and the four Branch 4 tests that expect output. `set -g suggests nothing` passes vacuously.

- [ ] **Step 3: Implement `fish-var`**

Create `mise-tasks/fish-var`, then `chmod +x mise-tasks/fish-var`:

```fish
#!/usr/bin/env fish
#MISE description="Set or unset a fish universal variable in chezmoi data, then apply"
#USAGE arg "<action>" help="set or unset"
#USAGE arg "<name>" help="variable name"
#USAGE arg "[value]" help="value (required for set)"

set -l repo (path resolve (status dirname)/..)
set -q DOTFILES_DATA_DIR; or set -l DOTFILES_DATA_DIR $repo/home/.chezmoidata
set -l name $usage_name

string match -qr '^[A-Za-z_][A-Za-z0-9_]*$' -- $name
or begin
    echo "fish-var: '$name' is not a valid variable name" >&2
    exit 1
end

switch $usage_action
    case set
        set -q usage_value; and test -n "$usage_value"
        or begin
            echo "fish-var: set needs a value" >&2
            exit 1
        end
        $repo/scripts/data-edit $DOTFILES_DATA_DIR/fish.json map-set fish_universal $name $usage_value
        or exit $status
    case unset
        $repo/scripts/data-edit $DOTFILES_DATA_DIR/fish.json map-unset fish_universal $name
        or exit $status
    case '*'
        echo "fish-var: action must be set or unset, got '$usage_action'" >&2
        exit 1
end

git -C $repo diff --stat -- home/.chezmoidata

set -q DOTFILES_NO_APPLY; and exit 0
if test $usage_action = unset
    # script 04 only sets; erase the live universal explicitly
    fish -c "set -eU $name"
    or exit $status
end
# script 04 re-runs because the rendered variable set changed
chezmoi apply --include=scripts
```

- [ ] **Step 4: Extend the nudge helper**

In `__chezmoi_nudge_task`, insert before the final `else`:

```fish
    else if string match -rq '^set\s+(-[a-zA-Z]*U[a-zA-Z]*|--universal)\s' -- $cmd
        # set -U / -Ux / -eU / --universal: any universal change
        echo 'fish-var set|unset <name> [value]'
```

- [ ] **Step 5: Run tests, deploy, commit**

```bash
make test-unit 2>&1 | tail -3
chezmoi apply ~/.config/fish/conf.d/chezmoi_nudge.fish </dev/null
git add mise-tasks/fish-var home/private_dot_config/private_fish/conf.d/chezmoi_nudge.fish tests/fish/mise_tasks_test.fish tests/fish/chezmoi_nudge_test.fish
git commit -m "feat(mise): fish-var task; nudge set -U toward it

Script 04 overwrites universal variables from data, so a hand-set
universal was lost on the next run unless recorded.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
Expected: `# ok`.

---

### Task 6: Deferred review minors (1, 3, 6, 7, 9) and CLAUDE.md

**Files:**
- Modify: `home/.chezmoiignore` (filter), `home/.chezmoiscripts/run_onchange_after_06-fish-plugins.sh.tmpl` (bootstrap), `tests/fish/fisher_chezmoi_test.fish`, `tests/fish/fisher_cold_install_test.fish`, `CLAUDE.md`

**Interfaces:**
- Consumes: nothing new.

- [ ] **Step 1: Write the failing tests**

In `tests/fish/fisher_chezmoi_test.fish`:

(a) Minor 6 — replace the two lines
```fish
set -l _chezmoi_bin (command -v chezmoi)
set -l no_fish (env PATH=/usr/bin:/bin $_chezmoi_bin execute-template < $_ignore_tmpl 2>&1; echo "status=$status")
```
with
```fish
set -l _chezmoi_bin (command -v chezmoi)
# PATH minus every directory holding a fish executable, wherever fish lives
set -l _no_fish_path
for dir in $PATH
    test -x $dir/fish; or set -a _no_fish_path $dir
end
set -l no_fish (env PATH=(string join : $_no_fish_path) $_chezmoi_bin execute-template < $_ignore_tmpl 2>&1; echo "status=$status")

@test "filtered PATH really has no fish" \
    (env PATH=(string join : $_no_fish_path) sh -c 'command -v fish' >/dev/null; and echo found; or echo none) = none
```

(b) Minor 7 — replace
```fish
@test "ignore template has no fisher:begin marker" \
    (string match -q '*fisher:begin*' < $_ignore_tmpl; and echo yes; or echo no) = no
```
with
```fish
@test "ignore template has no fisher:begin marker" \
    (test -f $_ignore_tmpl; and not string match -q '*fisher:begin*' < $_ignore_tmpl; and echo clean; or echo dirty) = clean
```
and replace
```fish
@test "install-packages script no longer touches fisher" \
    (string match -q '*fisher*' < $_chezmoi_src/.chezmoiscripts/run_onchange_02-install-packages.sh.tmpl; and echo yes; or echo no) = no
```
with
```fish
set -l _install_script $_chezmoi_src/.chezmoiscripts/run_onchange_02-install-packages.sh.tmpl
@test "install-packages script no longer touches fisher" \
    (test -f $_install_script; and not string match -q '*fisher*' < $_install_script; and echo clean; or echo dirty) = clean
```

(c) Minor 1 — append to the end of the file:
```fish
# Stray stdout from fish config must not become an ignore pattern
set -l _stray_xdg (mktemp -d)
mkdir -p $_stray_xdg/fish/conf.d
echo "echo '*'" > $_stray_xdg/fish/conf.d/stray.fish
set -l with_stray (env XDG_CONFIG_HOME=$_stray_xdg $_chezmoi_bin --config ~/.config/chezmoi/chezmoi.toml execute-template < $_ignore_tmpl 2>/dev/null)
trash $_stray_xdg

@test "stray fish stdout is not an ignore pattern" \
    (contains -- '*' $with_stray && echo leaked || echo filtered) = filtered
```

(d) Minor 3 — append after the `fish-plugins script succeeds when every listed plugin is installed` test:
```fish
@test "fish-plugins bootstrap fails fast when curl fails" \
    (string match -q '*curl -fsSL*' < $_plugins_script; and string match -q '*functions -q fisher; or exit 1*' < $_plugins_script; and echo yes; or echo no) = yes
```

In `tests/fish/fisher_cold_install_test.fish`, Minor 9 — replace `set -n | string match '_fisher_*_files'` with `set -Un | string match '_fisher_*_files'`. (No RED test: behaviour-preserving consistency edit — ledger it.)

- [ ] **Step 2: Run to verify they fail**

Run: `fish -c 'fishtape tests/fish/fisher_chezmoi_test.fish' 2>&1 | rg '^not ok'`
Expected `not ok`: `stray fish stdout is not an ignore pattern`, `fish-plugins bootstrap fails fast when curl fails`. The rewritten (a) and (b) tests pass now and must keep passing.

- [ ] **Step 3: Filter the ignore output (Minor 1)**

In `home/.chezmoiignore`, replace
```
{{ if lookPath "fish" -}}
{{ output "fish" "-c" "for v in (set -Un | string match '_fisher_*_files'); string replace -r '^~/' '' -- $$v; end; true" }}
{{- end }}
```
with
```
{{ if lookPath "fish" -}}
{{ range (output "fish" "-c" "for v in (set -Un | string match '_fisher_*_files'); string replace -r '^~/' '' -- $$v; end; true" | splitList "\n") -}}
{{ if hasPrefix ".config/fish/" . }}{{ . }}
{{ end -}}
{{ end -}}
{{- end }}
```
Then verify the render is unchanged apart from the filter: `chezmoi execute-template < home/.chezmoiignore | rg -c '^\.config/fish/'` must print the same count as before the edit (61 on this host: 3 static + 58 fisher).

- [ ] **Step 4: Fail fast in the bootstrap (Minor 3)**

In `run_onchange_after_06-fish-plugins.sh.tmpl`, replace
```fish
if not functions -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    or exit 1
end
```
with
```fish
if not functions -q fisher
    # `| source` returns source's status (0 on empty input), so check the result
    curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    functions -q fisher; or exit 1
end
```

- [ ] **Step 5: CLAUDE.md**

In the "Read-only chezmoi queries for ignore state" section replace `` enumerate with `set -n | string match '_fisher_*_files'` `` with `` enumerate with `set -Un | string match '_fisher_*_files'` `` (Minor 9).

In the "fisher is orchestrated by chezmoi" section:
- Replace the bullet starting `` - Plugin list: `` with:
```markdown
- Plugin list: `fish_plugins` in `home/.chezmoidata/fish.json`. `~/.config/fish/fish_plugins`
  is rendered from it. Change it with `mise run fish-plugin add|remove owner/repo`, not
  `fisher install` (the nudge prints the task usage).
```
- Replace the bullet starting `` - `run_onchange_after_06-fish-plugins` runs `` with (Minor 2):
```markdown
- `run_onchange_after_06-fish-plugins` runs `fisher update` after deploy, then fails if
  any listed plugin is missing (`fisher update` exits 0 when one download fails).
  fisher compares names lowercased, so case is harmless; the entry's shape matters — a
  trailing slash or whitespace names a different plugin. Tests and `fish-plugin` enforce
  `owner/repo`.
```
- Append to the `.chezmoiignore` bullet: `` Its output is filtered to lines starting with `.config/fish/`. If fish is on PATH but cannot start, `output` errors and every chezmoi command fails until fish is fixed. ``

Append a new section at the end of the file:
```markdown
## Data tasks (mise-tasks/)

Hand-made changes that belong in chezmoi data go through repo-scoped mise tasks, so they
are repeatable: `fish-plugin add|remove`, `pkg add|remove <manager> <name>`,
`fish-var set|unset`. Run them from anywhere with `mise -C ~/.local/share/chezmoi run …`;
`--help` shows usage. Each edits JSON through `scripts/data-edit` (the only JSON mutator),
prints the diff, then applies (named targets or `--include=scripts`, never a bare apply).
`pkg remove` uninstalls with the package manager because script 02 only installs.
Tests point tasks at a temp copy with `DOTFILES_DATA_DIR` and skip applying with
`DOTFILES_NO_APPLY=1`. The `chezmoi_nudge` hook prints the matching task's usage after
`brew|cargo|uv tool|fisher` installs and removals, and `set -U`. It recognises only the
kind of command and never parses installer arguments.
```

- [ ] **Step 6: Run tests, commit**

```bash
make test-unit 2>&1 | tail -3
chezmoi status </dev/null
git add home/.chezmoiignore home/.chezmoiscripts/run_onchange_after_06-fish-plugins.sh.tmpl tests/fish/fisher_chezmoi_test.fish tests/fish/fisher_cold_install_test.fish CLAUDE.md
git commit -m "fix(fish): filter ignore render, fail fast on fisher bootstrap, tighten tests

Closes deferred review minors: ignore output limited to .config/fish/
lines; script 06 bootstrap uses curl -f and checks fisher loaded; the
no-fish test builds PATH from directories without fish; two tests no
longer pass when their file is missing; set -Un everywhere. CLAUDE.md
documents the data tasks and corrects the plugin-spelling note.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
Expected: `# ok`; `chezmoi status` shows `MM .config/fish/config.fish` and `R .chezmoiscripts/06-fish-plugins.sh` (06 content changed) and nothing else.

---

### Task 7: Smoke run and host rollout

**Files:** none changed.

- [ ] **Step 1: Smoke**

```bash
make test-smoke > "$SCRATCH/smoke.log" 2>&1; echo "exit=$?"
rg -n '^(FAIL|not ok)|# (pass|fail)' "$SCRATCH/smoke.log"
```
(`$SCRATCH` = the session scratchpad.) Expected: `exit=0`, no `FAIL:`/`not ok`. The base and packages stages rebuild because the Dockerfile COPY changed.

- [ ] **Step 2: Host rollout**

```bash
chezmoi apply --include=scripts </dev/null; echo "exit=$?"
chezmoi status </dev/null
make test-unit 2>&1 | tail -2
```
Expected: `exit=0` (06 re-runs: `Updated 11 plugin/s`, then the per-plugin checks pass); status shows only `MM .config/fish/config.fish`; `# ok`.

- [ ] **Step 3: Report**

Report the commit range and that nothing is pushed. Pushing is the user's call.

## Out of scope

- Completion-file regeneration task.
- `brew_taps` + vector (memory: dotfiles-brew-taps-vector).
- Installer-added fish paths as data (memory: dotfiles-fish-paths-data).
- Docker `packages` stage rebuild when plugin data changes (review minor 8).

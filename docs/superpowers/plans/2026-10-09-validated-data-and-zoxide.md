# Validated data edits and zoxide Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Data edits can never write invalid or duplicate data, stale TOML references are gone, and directory-jump history moves from jethrokuan/z to zoxide so a failed write can no longer wipe it.

**Architecture:** `scripts/data-edit` computes the new JSON with jq, validates the *result* against one jq schema module (`scripts/data-schema.jq`), and replaces the file only when the result passes. zoxide is installed and configured through the repo's own tasks (`pkg`, `fish-plugin`) plus one managed conf.d file; the existing z history is imported once per machine.

**Tech Stack:** jq 1.7 (modules via `-L`), fish 4.8, mise file tasks, chezmoi v2.69, Homebrew zoxide 0.10.0, fishtape

**Spec:** the Background section below (decisions agreed in session 2026-10-08/09).

## Background

User decisions (do not re-litigate):

- jq enforces uniqueness and input validation; a transformation's output is validated before the file is updated.
- Stale `.chezmoidata.toml` references are updated to the JSON files where meaningful, deleted otherwise.
- Switch from jethrokuan/z to zoxide (recommended option chosen). History stays machine-local and is changed only by zoxide itself.

Facts established in session:

- z's data is `~/.local/share/z/data` (universal `Z_DATA`), machine-local, not managed or ignored by chezmoi. z's `z_uninstall` handler only erases `Z_DATA`; it never deletes the file.
- `__z_add` rewrites the whole file on every `cd`: awk output (stderr discarded) to a temp file, then `mv` over the data, without checking awk's status. A failed read/write replaces history with a truncated file. The C: drive was full on 2026-10-08 (SIGBUS crashes); current data's oldest entry is 2026-10-06. Root cause of the earlier loss is not provable; this write path is the plausible one.
- zoxide 0.10.0 is available from Homebrew and not yet installed. Data lives in `~/.local/share/zoxide/db.zo` (machine-local).
- Repo references to z: `tests/integration.sh:115-118`, `tests/fish/mise_tasks_test.fish:29`, `tests/fish/fisher_chezmoi_test.fish:79,106,117` (uses `__z.fish` as the sample fisher-owned file).
- Stale TOML references: `home/.chezmoiscripts/run_onchange_after_06-fish-plugins.sh.tmpl:4`, `tests/fish/fisher_chezmoi_test.fish:30`, `tests/fish/container/fresh_install_test.fish:15`. Historical plan docs are left as written.
- Tasks run `fish --no-config`; tests that can reach a real package manager must prove a stub resolves first. Real installs in this plan happen only in Task 4, deliberately, through the tasks.

## Global Constraints

- Commit directly on `main`. Conventional-commit subjects; end each message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Do not push.
- `scripts/data-edit` stays the only JSON mutator; the schema lives only in `scripts/data-schema.jq`.
- Host tier (`make test-unit`) is read-only against the live home and source.
- Never run a bare `chezmoi apply` (config.fish drift); named targets or `--include=scripts`.
- Use `trash`, not `rm`, for executor shell steps.

## Review Focus

1. **Existing live data violates the new schema** → every task edit would start failing. Test: `current data satisfies the schema` (Task 1).
2. **Case-only duplicate plugin (`PatrickF1/fzf.fish` beside `patrickf1/fzf.fish`)** → rejected, file untouched. Test in Task 1.
3. **Validation failure must leave the file byte-identical and mode-preserved.** Tests in Task 1.
4. **zoxide import before z is removed**, so history is never at zero. Task 4 orders install → import → verify → remove z.
5. **Both `z` definitions live at once** (plugin and zoxide) → whichever loads last wins. Task 4 removes the plugin before deploying the zoxide conf.d.

---

### Task 1: Schema-validated `data-edit`

**Files:**
- Create: `scripts/data-schema.jq`
- Modify: `scripts/data-edit`
- Test: `tests/fish/data_edit_test.fish`, `tests/fish/chezmoi_data_test.fish`

**Interfaces:**
- Produces: jq module `data-schema` with `def violations:` → array of human-readable strings (empty = valid). `data-edit` exit codes unchanged (0 ok / already listed, 1 rejected, 2 usage); a schema rejection prints each violation as `data-edit: <violation>` on stderr, exit 1, file untouched.

Schema rules (by key):
- top level is an object;
- every array: elements are strings, non-empty, no whitespace, unique;
- `fish_plugins`: each matches `^[^/\s]+/[^/\s]+(@\S+)?$`; unique ignoring case;
- `brew_packages*`, `cargo_plugins`, `cargo_binaries`, `uv_packages`: each matches `^[A-Za-z0-9@][A-Za-z0-9._+@/-]*$`;
- every object value (e.g. `fish_universal`): keys match `^[A-Za-z_][A-Za-z0-9_]*$`, values are strings.

- [ ] **Step 1: Write the failing tests**

Append to `tests/fish/data_edit_test.fish`, before `# only the files this test created`:

```fish
@echo "result validation"

function _fixture_data
    set -l f (mktemp --suffix .json)
    set -ga _fixtures $f
    echo '{"fish_plugins": ["patrickf1/fzf.fish"], "brew_packages": ["bat"], "fish_universal": {"EDITOR": "hx"}}' | jq . > $f
    chmod 644 $f
    echo $f
end

set -l f (_fixture_data)
set -l before (sha256sum < $f)
@test "case-only duplicate plugin is rejected" \
    ($_edit $f list-add fish_plugins PatrickF1/fzf.fish 2>/dev/null; echo $status) = 1
@test "rejected edit leaves the file byte-identical" \
    (sha256sum < $f) = $before

set -l f (_fixture_data)
@test "plugin without owner/repo shape is rejected" \
    ($_edit $f list-add fish_plugins fzf.fish 2>/dev/null; echo $status) = 1

set -l f (_fixture_data)
@test "package name with whitespace is rejected" \
    ($_edit $f list-add brew_packages 'two words' 2>/dev/null; echo $status) = 1

set -l f (_fixture_data)
@test "package name with ; is rejected" \
    ($_edit $f list-add brew_packages 'x;rm' 2>/dev/null; echo $status) = 1

set -l f (_fixture_data)
@test "invalid variable name is rejected" \
    ($_edit $f map-set fish_universal 1BAD x 2>/dev/null; echo $status) = 1

set -l f (_fixture_data)
@test "rejection names the violation" \
    (string match -q '*fish_plugins*' ($_edit $f list-add fish_plugins fzf.fish 2>&1); and echo yes; or echo no) = yes

set -l f (_fixture_data)
@test "valid edit keeps the file mode" \
    ($_edit $f list-add brew_packages fd; and stat -c %a $f) = 644

set -l bad (mktemp --suffix .json)
set -ga _fixtures $bad
echo '{not json' > $bad
@test "invalid JSON input is reported as invalid JSON" \
    (string match -q '*invalid JSON*' ($_edit $bad list-add pkgs a 2>&1); and echo yes; or echo no) = yes
```

Append to `tests/fish/chezmoi_data_test.fish`:

```fish
@echo "live data satisfies the schema"

for f in $_data/*.json
    @test (path basename $f)" satisfies the schema" \
        (jq -L $_repo_root/scripts 'include "data-schema"; violations | length' $f) = 0
end
```

- [ ] **Step 2: Run to verify they fail**

Run: `cd ~/.local/share/chezmoi && fish -c 'fishtape tests/fish/data_edit_test.fish tests/fish/chezmoi_data_test.fish' 2>&1 | rg '^not ok'`
Expected `not ok`: the five rejection tests, `rejection names the violation`, `valid edit keeps the file mode`, `invalid JSON input is reported as invalid JSON`, and both `satisfies the schema` tests (module missing). `rejected edit leaves the file byte-identical` passes vacuously now.

- [ ] **Step 3: Create the schema module**

`scripts/data-schema.jq`:

```jq
# Validation rules for chezmoi JSON data (home/.chezmoidata/*.json).
# `violations` returns an array of messages; empty means valid.
# Used by scripts/data-edit on every edit's result, and by tests on live data.

def package_keys: ["brew_packages", "brew_packages_linux", "brew_packages_darwin",
                   "cargo_plugins", "cargo_binaries", "uv_packages"];

def list_violations($k):
  .[$k] as $xs
  | [ $xs[] | select(type != "string" or . == "" or test("\\s"))
      | "\($k): entry \(tojson) must be a non-empty string without whitespace" ]
  + [ ($xs | group_by(.) | map(select(length > 1))[] | .[0])
      | "\($k): duplicate entry \(tojson)" ];

def plugin_violations:
  if has("fish_plugins") then
    [ .fish_plugins[] | strings | select(test("^[^/\\s]+/[^/\\s]+(@\\S+)?$") | not)
      | "fish_plugins: \(tojson) is not owner/repo" ]
    + [ (.fish_plugins | map(strings) | group_by(ascii_downcase) | map(select(length > 1))[])
        | "fish_plugins: \(map(tojson) | join(", ")) differ only by case" ]
  else [] end;

def package_violations:
  [ package_keys[] as $k | select(has($k)) | .[$k][] | strings
    | select(test("^[A-Za-z0-9@][A-Za-z0-9._+@/-]*$") | not)
    | "\($k): \(tojson) is not a valid package name" ];

def map_violations($k):
  [ .[$k] | to_entries[]
    | (select(.key | test("^[A-Za-z_][A-Za-z0-9_]*$") | not)
        | "\($k): \(.key | tojson) is not a valid variable name"),
      (select(.value | type != "string")
        | "\($k).\(.key): value must be a string") ];

def violations:
  if type != "object" then ["top level must be an object"]
  else
    [ keys[] as $k
      | if (.[$k] | type) == "array" then list_violations($k)[]
        elif (.[$k] | type) == "object" then map_violations($k)[]
        else empty end ]
    + plugin_violations + package_violations
  end;
```

- [ ] **Step 4: Validate in `data-edit`**

In `scripts/data-edit`:

(a) Replace the key-existence check block
```fish
jq -e --arg k $key 'has($k)' $file >/dev/null 2>&1
or begin
    echo "data-edit: key '$key' not in $file" >&2
    exit 1
end
```
with
```fish
jq -e . $file >/dev/null 2>&1
or begin
    echo "data-edit: $file is not readable valid JSON (invalid JSON)" >&2
    exit 1
end
jq -e --arg k $key 'has($k)' $file >/dev/null
or begin
    echo "data-edit: key '$key' not in $file" >&2
    exit 1
end
```

(b) Replace the write block at the end
```fish
set -l tmp (mktemp -p (path dirname $file) .data-edit.XXXXXX)
or exit 1
jq $jqargs $filter $file > $tmp
or begin; command rm -f $tmp; exit 1; end
mv $tmp $file
```
with
```fish
set -l schema_dir (path resolve (status dirname))
set -l tmp (mktemp -p (path dirname $file) .data-edit.XXXXXX)
or exit 1
jq $jqargs $filter $file > $tmp
or begin; command rm -f $tmp; exit 1; end

# validate the result, not the input: only a fully valid file replaces the data
set -l violations (jq -r -L $schema_dir 'include "data-schema"; violations[]' $tmp)
if test (count $violations) -gt 0
    printf 'data-edit: %s\n' $violations >&2
    command rm -f $tmp
    exit 1
end

chmod (stat -c %a $file) $tmp
mv $tmp $file
```

- [ ] **Step 5: Run tests and commit**

```bash
make test-unit 2>&1 | tail -3
git add scripts/data-schema.jq scripts/data-edit tests/fish/data_edit_test.fish tests/fish/chezmoi_data_test.fish
git commit -m "feat(scripts): validate every data edit's result against a jq schema

data-edit now builds the new JSON, checks it with scripts/data-schema.jq
(unique non-empty entries, owner/repo plugins unique ignoring case, safe
package names, valid variable names) and replaces the file only if the
whole result passes. Invalid JSON is reported as such; file mode is kept.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
Expected: `# ok`.

---

### Task 2: Stale `.chezmoidata.toml` references

**Files:**
- Modify: `home/.chezmoiscripts/run_onchange_after_06-fish-plugins.sh.tmpl:4`, `tests/fish/fisher_chezmoi_test.fish:30`, `tests/fish/container/fresh_install_test.fish:15`
- Test: `tests/fish/chezmoi_data_test.fish`

- [ ] **Step 1: Write the failing test**

Append to `tests/fish/chezmoi_data_test.fish`:

```fish
@echo "no stale TOML data references"

@test "no live file mentions .chezmoidata.toml" \
    (git -C $_repo_root grep -l '\.chezmoidata\.toml' -- . ':!docs/' | count) = 0
```

- [ ] **Step 2: Run to verify it fails**

Run: `fish -c 'fishtape tests/fish/chezmoi_data_test.fish' 2>&1 | rg 'stale|not ok'`
Expected: `not ok … no live file mentions .chezmoidata.toml`.

- [ ] **Step 3: Update the references**

- Script 06 line 4: `# .chezmoidata.toml fish_plugins) exists for `fisher update` to read.` → `# home/.chezmoidata/fish.json fish_plugins) exists for `fisher update` to read.`
- `fisher_chezmoi_test.fish:30`: `@echo "fish_plugins: rendered from .chezmoidata.toml"` → `@echo "fish_plugins: rendered from .chezmoidata/fish.json"`
- `container/fresh_install_test.fish:15`: `@echo "fresh install: fish plugins from .chezmoidata.toml"` → `@echo "fresh install: fish plugins from .chezmoidata/fish.json"`

Then run `git grep -n '\.chezmoidata\.toml' -- . ':!docs/'`; any remaining hit is deleted if it describes the old file and rewritten to the JSON path if it still means "the data".

- [ ] **Step 4: Run tests and commit**

```bash
make test-unit 2>&1 | tail -3
git add -u home tests
git commit -m "docs(chezmoi): point remaining data references at .chezmoidata/*.json

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
Expected: `# ok`. (Script 06 changes, so it re-runs on the next scripts apply; it is idempotent.)

---

### Task 3: Tests stop depending on z

**Files:**
- Modify: `tests/fish/fisher_chezmoi_test.fish` (lines 79, 106, 117), `tests/integration.sh` (115-118), `tests/fish/mise_tasks_test.fish` (28-29)

**Interfaces:**
- Produces: tests use `.config/fish/functions/fisher.fish` as the sample fisher-owned file (fisher always owns it) and `jorgebucaran/autopair.fish` as the sample removable plugin.

- [ ] **Step 1: Replace the sample file and plugin**

- In `fisher_chezmoi_test.fish`, replace every `.config/fish/functions/__z.fish` with `.config/fish/functions/fisher.fish`, and rename the test `rendered ignore lists a fisher-owned file` unchanged otherwise.
- In `tests/integration.sh`, replace `'.config/fish/functions/__z.fish'` with `'.config/fish/functions/fisher.fish'` and the two messages' `__z.fish` with `fisher.fish`.
- In `mise_tasks_test.fish`, replace the `fish-plugin remove drops the plugin` test with one that asserts the entry exists first, so it cannot pass vacuously:

```fish
set -l d (_task_env)
@test "sample plugin is present before removal" \
    (jq -r '.fish_plugins | index("jorgebucaran/autopair.fish") != null' $d/fish.json) = true
@test "fish-plugin remove drops the plugin" \
    (_run $d fish-plugin remove jorgebucaran/autopair.fish >/dev/null 2>&1; jq -r '.fish_plugins | index("jorgebucaran/autopair.fish")' $d/fish.json) = null
```

- [ ] **Step 2: Run tests and commit**

```bash
make test-unit 2>&1 | tail -3
bash -n tests/integration.sh && echo syntax-ok
git add tests/fish/fisher_chezmoi_test.fish tests/integration.sh tests/fish/mise_tasks_test.fish
git commit -m "test(fish): use fisher's own files as samples instead of z

z is about to be replaced by zoxide; fisher always owns fisher.fish.
The plugin-removal test now asserts its sample exists first.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
Expected: `# ok`, `syntax-ok`. (Refactor of test fixtures: tests pass before and after; no RED step — ledger it.)

---

### Task 4: Switch to zoxide

**Files:**
- Modify (via tasks): `home/.chezmoidata/packages.json` (`brew_packages` += `zoxide`), `home/.chezmoidata/fish.json` (`fish_plugins` −= `jethrokuan/z`)
- Create: `home/private_dot_config/private_fish/conf.d/zoxide.fish`
- Test: `tests/fish/zoxide_test.fish` (new), `Makefile`

**Interfaces:**
- Consumes: `pkg`, `fish-plugin` tasks; validated `data-edit` (Task 1).

- [ ] **Step 1: Write the failing test**

Create `tests/fish/zoxide_test.fish`:

```fish
#!/usr/bin/env fish
# zoxide replaces jethrokuan/z and keeps the `z` command.
# Run: fishtape tests/fish/zoxide_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _data $_repo_root/home/.chezmoidata

@test "zoxide is in brew_packages" \
    (jq -r '.brew_packages | index("zoxide") != null' $_data/packages.json) = true

@test "jethrokuan/z is no longer a fish plugin" \
    (jq -r '.fish_plugins | index("jethrokuan/z")' $_data/fish.json) = null

@test "zoxide conf.d is managed" \
    (test -f $_repo_root/home/private_dot_config/private_fish/conf.d/zoxide.fish; and echo yes; or echo no) = yes

@test "interactive fish defines z from zoxide" \
    (fish -i -c 'functions z' 2>/dev/null | string match -q '*__zoxide_z*'; and echo yes; or echo no) = yes

@test "zoxide has history (imported from z)" \
    (command -q zoxide; and test (zoxide query -l 2>/dev/null | count) -gt 0; and echo yes; or echo no) = yes
```

Add it to `test-unit` in `Makefile`.

- [ ] **Step 2: Run to verify it fails**

Run: `fish -c 'fishtape tests/fish/zoxide_test.fish' 2>&1 | rg '^(not )?ok'`
Expected: all five `not ok`.

- [ ] **Step 3: Install zoxide through the task**

```bash
mise -C ~/.local/share/chezmoi run pkg add brew zoxide
command -v zoxide && zoxide --version
```
Expected: the diff shows `zoxide` added; script 02 re-runs (long: full brew/cargo/uv pass, mostly no-ops); `zoxide 0.10.0`. If 02's run reports ⚠ for cargo (`vector`, known), that is pre-existing.

- [ ] **Step 4: Import z history before removing z**

```bash
zoxide import --help | rg -i '\bz\b'
cp ~/.local/share/z/data "$SCRATCH/z-data.backup"
zoxide import --from=z ~/.local/share/z/data
zoxide query -l | head -5
```
Expected: help lists `z` as an import source; the query lists directories that appear in the z data. The z data file is left in place (machine-local backup; the user may delete it later).

- [ ] **Step 5: Remove the z plugin through the task**

```bash
mise -C ~/.local/share/chezmoi run fish-plugin remove jethrokuan/z
test -e ~/.config/fish/functions/__z.fish && echo STILL || echo removed
```
Expected: diff shows the removal; script 06 runs `fisher update`, which uninstalls z (it prints "To completely erase z's data, remove: …" — do not remove it); `removed`.

- [ ] **Step 6: Add the zoxide conf.d**

`home/private_dot_config/private_fish/conf.d/zoxide.fish`:

```fish
# zoxide replaces jethrokuan/z and keeps the `z` command. History lives per machine
# in ~/.local/share/zoxide and is only ever written by zoxide.
status is-interactive; and command -q zoxide; and zoxide init fish --cmd z | source
```

```bash
chezmoi apply ~/.config/fish/conf.d/zoxide.fish </dev/null
```

- [ ] **Step 7: Run tests and commit**

```bash
fish -c 'fishtape tests/fish/zoxide_test.fish' 2>&1 | rg '^(not )?ok'
make test-unit 2>&1 | tail -3
chezmoi status </dev/null
git add home/.chezmoidata home/private_dot_config/private_fish/conf.d/zoxide.fish tests/fish/zoxide_test.fish Makefile
git commit -m "feat(fish): replace jethrokuan/z with zoxide

z rewrote its whole data file on every cd without checking the write, so
a failed write (e.g. a full disk) replaced history with a truncated file.
zoxide keeps the z command, writes its database atomically, and history
was imported once from z. Done through the pkg and fish-plugin tasks.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
Expected: all five zoxide tests `ok`; `# ok`; status only `MM .config/fish/config.fish`.

---

### Task 5: Smoke run and CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: CLAUDE.md**

In the "Data tasks (mise-tasks/)" section, after the sentence ending `(the only JSON mutator),`, insert: `which validates the whole result against \`scripts/data-schema.jq\` (unique entries, plugin \`owner/repo\` unique ignoring case, safe package names, valid variable names) before replacing the file;`

Append to the "fisher is orchestrated by chezmoi" section:
```markdown
- Directory jumping is zoxide (`conf.d/zoxide.fish`, `--cmd z`), not jethrokuan/z: z
  rewrote its data on every `cd` without checking the write. zoxide history is per
  machine (`~/.local/share/zoxide`); on a new machine with old z data, import it once
  with `zoxide import --from=z ~/.local/share/z/data`.
```

- [ ] **Step 2: Smoke**

```bash
df -h /mnt/c | tail -1
make test-smoke > "$SCRATCH/smoke.log" 2>&1; echo "exit=$?"
rg -n '^(FAIL|not ok)|# (pass|fail)' "$SCRATCH/smoke.log"
```
Expected: C: has well over 30 GB free before starting; `exit=0`; no `FAIL:`/`not ok`. The zoxide tests are host-tier (they read installed state) and are not in the container tier.

- [ ] **Step 3: Commit**

```bash
make test-unit 2>&1 | tail -2
git add CLAUDE.md
git commit -m "docs(chezmoi): document validated data edits and zoxide

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

## Out of scope

- Deleting `~/.local/share/z/data` (kept as a per-machine backup; user's call).
- Remaining deferred minors not covered here: add-of-existing still applies, task diff output, `DOTFILES_NO_APPLY` value semantics, `pkg remove` not applying.
- brew taps + vector; fish paths as data.

# chezmoi-native fisher plugins Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make chezmoi the single owner of fish plugin orchestration: the plugin list is data, plugins install after files are deployed, and the fisher ignore block is rendered at template time instead of written into the checked-in source by a runtime hook.

**Architecture:** `fish_plugins` moves into `.chezmoidata.toml` and the deployed `~/.config/fish/fish_plugins` is rendered from it. A new `run_onchange_after_06-fish-plugins` script runs `fisher update` after files are deployed. `.chezmoiignore` becomes a template that renders fisher-owned paths from fisher's own `_fisher_*_files` universal variables; the `_fisher_sync_chezmoiignore` hook and its conf.d file are retired via `.chezmoiremove`.

**Tech Stack:** chezmoi v2.69 templates, fish 4.8 / fisher 4.4.8, fishtape, bash, Docker BuildKit

**Spec:** the Background section below (design agreed in session, 2026-10-06/07). No separate spec file.

## Background

Three files each had more than one owner, which caused every problem found while splitting the tests:

| File | Roles before this plan |
|---|---|
| `fish_plugins` | deployed config, input to the install script, *and* rewritten by fisher |
| `.chezmoiignore` | checked-in chezmoi config, *and* rewritten at runtime by `_fisher_sync_chezmoiignore` |
| `run_onchange_02-install-packages` | reads `~/.config/fish/...` but runs before chezmoi deploys it |

Observed failures: host tests overwrote unapplied source edits; `.chezmoiignore` was dirtied after every test run; on a fresh apply `fisher install < ~/.config/fish/fish_plugins` reads a missing file, installs only fisher, and the next line fails with `Unknown command: _fisher_sync_chezmoiignore` (both visible in the smoke build log). The Docker `packages` stage had to hand-copy `fish_plugins` to keep the old script rendering.

Facts verified before writing this plan (do not re-litigate):

- `fisher update` reads `~/.config/fish/fish_plugins` and writes it back with the file's own entries first, in file order (`fisher.fish` lines 209-220). A data-rendered file round-trips unchanged provided entries match fisher's spelling.
- fisher records each plugin's installed files in universal `_fisher_<plugin>_files`, paths beginning with a literal `~/`. fish has no wildcard variable expansion: enumerate with `set -Un | string match '_fisher_*_files'` and `$$var`.
- `fish --no-config` does **not** load universal variables. The template must run plain `fish -c`.
- Rendering the fisher block via `{{ output "fish" "-c" ... }}` returned 58 paths and cost ~30 ms over a plain `chezmoi managed`.
- On a scratch copy of the source, a templated `.chezmoiignore` made `chezmoi add --dry-run` report `warning: ignoring` for fisher files and the static entries; `.chezmoiremove` planned deletion of `conf.d/fisher_chezmoi_sync.fish`. `.chezmoiremove` errors with `inconsistent state` if the source file still exists, so the source file must be deleted in the same change.
- Unmanaged files under `~/.config/fish` that are **not** fisher-owned and were silently in the old block: `completions/chezmoi.fish`, `conf.d/fish_frozen_key_bindings.fish` (fish 4 generates it), plus `completions/swamp.fish` (tool-generated, was only being added by the old sync). These become static ignore lines.
- `chezmoi source-path` returns `.../chezmoi/home` (the `.chezmoiroot`), not the repo root.

## Global Constraints

- Commit directly on `main`, matching repo history. Conventional-commit subjects. End every commit message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- No script filenames in `Makefile` or `Dockerfile` (constraint carried from `2026-06-18-chezmoi-test-architecture.md`).
- Host tier (`make test-unit`) is read-only against the live home and source. Anything that writes goes in `tests/fish/container/`.
- During Tasks 1-5, apply only named targets (`chezmoi apply <path>`). A full `chezmoi apply` re-runs script 02 (brew/cargo/uv installs) and runs fisher over the network; that happens once, in Task 6.
- chezmoi `diff`/`add` calls in tests use `--no-pager` and `</dev/null` (a large diff otherwise blocks in the pager).
- New scripts fail on error: `set -eufo pipefail`, no `|| echo "⚠ ..."` swallowing.
- Use `trash`, not `rm`, in shell steps run by the executor.

## Review Focus

1. **Fresh machine, fish not yet on PATH when `.chezmoiignore` first renders** → render must succeed with only the static lines. Test added in Task 3 (`renders without fish on PATH`).
2. **fish installed but fisher has never run (no `_fisher_*_files`)** → render must succeed, fisher block empty. Test added in Task 3 (`renders with empty fish universal scope`).
3. **User runs `fisher install foo` interactively** → deployed `fish_plugins` drifts from data; they should be told where the list lives. Nudge + tests in Task 4; drift is visible via `chezmoi diff` (Task 2 test).
4. **Data entry spelled differently from fisher's canonical form** (case, trailing slash) → `fisher update` rewrites the file and `chezmoi diff` is non-empty forever. Container test `fish_plugins unchanged by fisher update` in Task 5.
5. **A second machine pulls the new source but has the old hook deployed and runs `fisher install` before applying** → old hook overwrites the templated `.chezmoiignore` in the source. Mitigation: roll out with `chezmoi update` (pull + apply in one step), Task 6; Task 3 integration check asserts the hook file is gone after apply.

---

### Task 1: Commit the read-only host test split

The working tree already holds the host-side split from the previous session. Commit only the two host test files now; the container files, `Makefile`, `Dockerfile` and `CLAUDE.md` stay uncommitted until Task 5, where they go green.

**Files:**
- Commit (already modified): `tests/fish/fisher_chezmoi_test.fish`, `tests/fish/fisher_cold_install_test.fish`

**Interfaces:**
- Produces: `fisher_cold_install_test.fish` read-only check "`<rel> ignored by chezmoi add`" over every `_fisher_*_files` path; later tasks rely on it unchanged.

- [ ] **Step 1: Verify the host suite passes and writes nothing to the source**

Run:
```bash
cd ~/.local/share/chezmoi
make test-unit 2>&1 | tail -3
git status --short
```
Expected: `# pass 138` / `# ok`; status lists only `CLAUDE.md`, `Dockerfile`, `Makefile`, the two fisher tests, and `?? tests/fish/container/` (plus this plan file). `home/.chezmoiignore` must **not** appear.

- [ ] **Step 2: Commit**

```bash
git add tests/fish/fisher_chezmoi_test.fish tests/fish/fisher_cold_install_test.fish
git commit -m "test(fish): make host-tier fisher tests read-only

Replace the real \`chezmoi add\` with a dry-run check over fisher's own
_fisher_*_files record, and drop sync-behavior tests that wrote to the
live source and ~/.config.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Plugin list as data; install plugins after deploy

**Files:**
- Modify: `home/.chezmoidata.toml` (add `fish_plugins` before the `[fish_universal]` table)
- Rename: `home/private_dot_config/private_fish/fish_plugins` → `home/private_dot_config/private_fish/fish_plugins.tmpl`
- Create: `home/.chezmoiscripts/run_onchange_after_06-fish-plugins.sh.tmpl`
- Modify: `home/.chezmoiscripts/run_onchange_02-install-packages.sh.tmpl` (remove line 3, `fish_bin` lines, `install_fish_plugins`)
- Modify: `Dockerfile` (packages stage: remove the `fish_plugins` COPY)
- Modify: `tests/orchestration.sh` (expect script 06)
- Test: `tests/fish/fisher_chezmoi_test.fish`

**Interfaces:**
- Produces: chezmoi data key `fish_plugins` (list of strings, fisher's canonical spelling). Script target name `06-fish-plugins`. Tasks 3 and 5 read `.fish_plugins`.

- [ ] **Step 1: Write the failing tests**

Append to the "structure after chezmoi apply" section of `tests/fish/fisher_chezmoi_test.fish`, after the `chezmoi source-path resolves` test:

```fish
# ── plugin list is chezmoi data ───────────────────────────────────────────────

@echo "fish_plugins: rendered from .chezmoidata.toml"

@test "fish_plugins data renders the deployed plugin list" \
    "$(chezmoi execute-template '{{ range .fish_plugins }}{{ . }}{{ "\n" }}{{ end }}' 2>&1)" = "$(cat ~/.config/fish/fish_plugins)"

@test "fish_plugins has no pending chezmoi diff" \
    (chezmoi diff --no-pager ~/.config/fish/fish_plugins </dev/null 2>&1 | count) = 0

set -l _plugins_script $_chezmoi_src/.chezmoiscripts/run_onchange_after_06-fish-plugins.sh.tmpl

@test "fish-plugins script renders fisher update" \
    (chezmoi execute-template < $_plugins_script 2>/dev/null | string match -q 'fisher update'; and echo yes; or echo no) = yes

# test -f first: `bash -n` on empty stdin succeeds, which would pass vacuously
@test "fish-plugins script passes bash syntax check" \
    (test -f $_plugins_script; and chezmoi execute-template < $_plugins_script 2>/dev/null | bash -n; and echo yes; or echo no) = yes

@test "install-packages script no longer touches fisher" \
    (string match -q '*fisher*' < $_chezmoi_src/.chezmoiscripts/run_onchange_02-install-packages.sh.tmpl; and echo yes; or echo no) = no
```

- [ ] **Step 2: Run to verify they fail**

Run: `cd ~/.local/share/chezmoi && fish -c 'fishtape tests/fish/fisher_chezmoi_test.fish' 2>&1 | rg '^not ok'`
Expected `not ok`: `fish_plugins data renders the deployed plugin list` (data key missing → template error), `fish-plugins script renders fisher update` and `fish-plugins script passes bash syntax check` (script missing), `install-packages script no longer touches fisher`. `fish_plugins has no pending chezmoi diff` passes now and must still pass after Step 9 — it guards the rename.

- [ ] **Step 3: Add the data key**

In `home/.chezmoidata.toml`, insert immediately after the closing `]` of `uv_packages` and before `[fish_universal]` (TOML top-level keys must precede tables):

```toml
fish_plugins = [
  "patrickf1/fzf.fish",
  "jethrokuan/z",
  "jorgebucaran/autopair.fish",
  "jorgebucaran/getopts.fish",
  "jorgebucaran/hydro",
  "jorgebucaran/nvm.fish",
  "jorgebucaran/replay.fish",
  "meaningful-ooo/sponge",
  "nickeb96/puffer-fish",
  "jorgebucaran/fisher",
  "jorgebucaran/fishtape",
]
```

Order and spelling are copied verbatim from the current `fish_plugins` so the rendered file is byte-identical.

- [ ] **Step 4: Render `fish_plugins` from data**

```bash
git mv home/private_dot_config/private_fish/fish_plugins home/private_dot_config/private_fish/fish_plugins.tmpl
```

Replace the entire contents of `fish_plugins.tmpl` with:

```
{{ range .fish_plugins -}}
{{ . }}
{{ end -}}
```

- [ ] **Step 5: Create the after-deploy plugin script**

`home/.chezmoiscripts/run_onchange_after_06-fish-plugins.sh.tmpl`:

```bash
#!/bin/bash
set -eufo pipefail
# Runs after files are deployed, so ~/.config/fish/fish_plugins (rendered from
# .chezmoidata.toml fish_plugins) exists for `fisher update` to read.
# Re-runs when the list changes: {{ .fish_plugins | join " " }}

{{ if eq .chezmoi.os "darwin" -}}
fish_bin={{ or (lookPath "fish") "/opt/homebrew/bin/fish" }}
{{ else -}}
fish_bin={{ or (lookPath "fish") "/home/linuxbrew/.linuxbrew/bin/fish" }}
{{ end -}}

"$fish_bin" <<'FISH'
if not functions -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    or exit 1
end
fisher update
FISH
```

- [ ] **Step 6: Remove fisher from script 02**

In `home/.chezmoiscripts/run_onchange_02-install-packages.sh.tmpl`:

Delete line 3 (it `include`s the old `fish_plugins` path and would now fail to render):
```
# fish plugins: {{ include (joinPath .chezmoi.sourceDir "private_dot_config" "private_fish" "fish_plugins") | sha256sum }}
```

Replace the PATH setup block:
```
{{ if eq .chezmoi.os "darwin" -}}
eval "$(/opt/homebrew/bin/brew shellenv)"
fish_bin={{ or (lookPath "fish") "/opt/homebrew/bin/fish" }}
{{ else -}}
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fish_bin={{ or (lookPath "fish") "/home/linuxbrew/.linuxbrew/bin/fish" }}
{{ end -}}
```
with:
```
{{ if eq .chezmoi.os "darwin" -}}
eval "$(/opt/homebrew/bin/brew shellenv)"
{{ else -}}
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
{{ end -}}
```

Delete the whole function:
```
install_fish_plugins() {
    $fish_bin << 'FISH'
if not functions -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher install jorgebucaran/fisher
end
fisher install < ~/.config/fish/fish_plugins
_fisher_sync_chezmoiignore; or true
FISH
}
```

Delete the call and its comment at the end of the file:
```
# Fish plugins run after brew (needs brew's fish binary)
install_fish_plugins || echo "⚠  fisher install exited non-zero — check output above"
```

Also update the section header `# -- Concurrent installs, then fish ---...` to `# -- Concurrent installs ---------------------------------------------------------`.

- [ ] **Step 7: Drop the Dockerfile copy**

In `Dockerfile`, `packages` stage, delete:
```
# install-packages template includes fish_plugins for hash tracking
COPY --chown=testuser:testuser \
    home/private_dot_config/private_fish/fish_plugins \
    /home/testuser/.local/share/chezmoi/home/private_dot_config/private_fish/fish_plugins
```

- [ ] **Step 8: Expect script 06 in orchestration**

In `tests/orchestration.sh`, add `"06-fish-plugins"` as the last element of `SCRIPTS=(...)`, and extend the unexpected-scripts regex:
```bash
    | grep -vE "^(01-bootstrap-package-managers|02-install-packages|03-bat-symlink|04-fish-universal|05-terminal-theme-timer|06-fish-plugins)$" \
```

- [ ] **Step 9: Apply the one target and run tests**

```bash
chezmoi apply ~/.config/fish/fish_plugins
make test-unit 2>&1 | tail -3
make test-orchestration
git status --short home/.chezmoiignore
```
Expected: apply is a no-op (content identical); `# ok`; orchestration prints `ok: 05-terminal-theme-timer before 06-fish-plugins` and `ok: no unexpected scripts in plan`; `.chezmoiignore` not listed.

- [ ] **Step 10: Commit**

```bash
git add home/.chezmoidata.toml home/private_dot_config/private_fish/fish_plugins.tmpl \
  home/.chezmoiscripts/run_onchange_after_06-fish-plugins.sh.tmpl \
  home/.chezmoiscripts/run_onchange_02-install-packages.sh.tmpl \
  Dockerfile tests/orchestration.sh tests/fish/fisher_chezmoi_test.fish
git commit -m "feat(fish): fish plugins as chezmoi data, installed after deploy

fish_plugins is rendered from .chezmoidata.toml and run_onchange_after_06
runs \`fisher update\` once the file is deployed. Script 02 previously read
~/.config/fish/fish_plugins before it existed on a fresh apply, so only
fisher itself was installed.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Render the fisher ignore block; retire the sync hook

**Files:**
- Modify: `home/.chezmoiignore` (replace entirely with a template)
- Create: `home/.chezmoiremove`
- Delete: `home/private_dot_config/private_fish/conf.d/fisher_chezmoi_sync.fish`
- Modify: `tests/fish/fisher_chezmoi_test.fish`, `tests/fish/fisher_cold_install_test.fish`, `tests/integration.sh`

**Interfaces:**
- Consumes: nothing from Task 2.
- Produces: no function `_fisher_sync_chezmoiignore` anywhere; `.chezmoiignore` has no `# fisher:begin`/`# fisher:end` markers. Task 5 asserts the hook file is absent.

- [ ] **Step 1: Write the failing tests**

In `tests/fish/fisher_chezmoi_test.fish`:

Delete the test `fisher_chezmoi_sync conf.d deployed` (lines `@test "fisher_chezmoi_sync conf.d deployed" \` and the line after it).

Replace the whole `# ── ignore file shape ───` section (from that header to end of file) with:

```fish
# ── ignore rendered from fisher state ─────────────────────────────────────────

@echo ".chezmoiignore: rendered from fisher's record"

set -l _ignore_tmpl $_chezmoi_src/.chezmoiignore
set -l rendered (chezmoi execute-template < $_ignore_tmpl 2>/dev/null)

@test "retired sync hook not deployed" \
    (test -e ~/.config/fish/conf.d/fisher_chezmoi_sync.fish && echo yes || echo no) = no

@test "ignore template has no fisher:begin marker" \
    (string match -q '*fisher:begin*' < $_ignore_tmpl; and echo yes; or echo no) = no

@test "rendered ignore lists a fisher-owned file" \
    (contains -- .config/fish/functions/__z.fish $rendered && echo yes || echo no) = yes

@test "rendered ignore lists static non-fisher entries" \
    (contains -- .config/fish/completions/swamp.fish $rendered && echo yes || echo no) = yes

@test "rendered ignore omits chezmoi-managed __append_pipe_fzf.fish" \
    (contains -- .config/fish/functions/__append_pipe_fzf.fish $rendered && echo yes || echo no) = no

@test "rendered ignore has no duplicate entries" \
    (printf '%s\n' $rendered | sort | uniq -d | count) = 0

# Fresh machine: fish not on PATH yet → only static lines, no error
set -l _chezmoi_bin (command -v chezmoi)
set -l no_fish (env PATH=/usr/bin:/bin $_chezmoi_bin execute-template < $_ignore_tmpl 2>&1; echo "status=$status")

@test "renders without fish on PATH" \
    $no_fish[-1] = status=0

@test "without fish on PATH no fisher entries render" \
    (contains -- .config/fish/functions/__z.fish $no_fish && echo yes || echo no) = no

# fish present but fisher never ran → empty universal scope, still no error
set -l _empty_xdg (mktemp -d)
set -l no_fisher (env XDG_CONFIG_HOME=$_empty_xdg $_chezmoi_bin --config ~/.config/chezmoi/chezmoi.toml execute-template < $_ignore_tmpl 2>&1; echo "status=$status")
trash $_empty_xdg

@test "renders with empty fish universal scope" \
    $no_fisher[-1] = status=0

@test "with empty universal scope no fisher entries render" \
    (contains -- .config/fish/functions/__z.fish $no_fisher && echo yes || echo no) = no
```

In `tests/fish/fisher_cold_install_test.fish`, delete line 8 and the blank line after it:
```fish
source ~/.config/fish/conf.d/fisher_chezmoi_sync.fish 2>/dev/null
```

- [ ] **Step 2: Run to verify they fail**

Run: `fish -c 'fishtape tests/fish/fisher_chezmoi_test.fish' 2>&1 | rg '^not ok'`
Expected `not ok`: `retired sync hook not deployed`, `ignore template has no fisher:begin marker`, `rendered ignore lists static non-fisher entries` (swamp.fish is not in the current block), `without fish on PATH no fisher entries render` and `with empty universal scope no fisher entries render` (today's static block always contains `__z.fish`). The remaining tests in the section pass now and must still pass after Step 3.

- [ ] **Step 3: Replace `.chezmoiignore` with the template**

Replace the entire contents of `home/.chezmoiignore`:

```
# Generated under ~/.config/fish by fish or other tools; not fisher-owned
.config/fish/completions/chezmoi.fish
.config/fish/completions/swamp.fish
.config/fish/conf.d/fish_frozen_key_bindings.fish
# fisher-owned files, read from fisher's own record at render time.
# Plain `fish -c`: --no-config would hide universal variables.
{{ if lookPath "fish" -}}
{{ output "fish" "-c" "for v in (set -Un | string match '_fisher_*_files'); string replace -r '^~/' '' -- $$v; end; true" }}
{{- end }}
```

(This also drops the stray `_chezmoi_add_test.fish` line left by the old test.)

- [ ] **Step 4: Retire the hook**

```bash
git rm home/private_dot_config/private_fish/conf.d/fisher_chezmoi_sync.fish
printf '%s\n' .config/fish/conf.d/fisher_chezmoi_sync.fish > home/.chezmoiremove
chezmoi apply ~/.config/fish/conf.d/fisher_chezmoi_sync.fish
```

The source file and the `.chezmoiremove` entry must change together; with both present chezmoi errors `inconsistent state`.

- [ ] **Step 5: Update integration checks**

In `tests/integration.sh`, remove `"$HOME/.config/fish/conf.d/fisher_chezmoi_sync.fish" \` from the deployed-files list, and replace everything from `# chezmoiignore must have fisher block` up to (not including) `exit $fail` with:

```bash
# retired sync hook must be removed by .chezmoiremove
if [[ -e "$HOME/.config/fish/conf.d/fisher_chezmoi_sync.fish" ]]; then
    check_fail "fisher_chezmoi_sync.fish still deployed"
else
    ok "fisher_chezmoi_sync.fish removed"
fi

# rendered ignore must cover fisher files and skip user-managed ones
chezmoi_src=$(chezmoi source-path 2>/dev/null)
rendered_ignore=$(chezmoi execute-template < "$chezmoi_src/.chezmoiignore" 2>/dev/null)
if grep -qxF '.config/fish/functions/__z.fish' <<<"$rendered_ignore"; then
    ok "fisher-owned __z.fish in rendered .chezmoiignore"
else
    check_fail "fisher-owned __z.fish missing from rendered .chezmoiignore"
fi
if grep -qF '__append_pipe_fzf.fish' <<<"$rendered_ignore"; then
    check_fail "__append_pipe_fzf.fish incorrectly in rendered .chezmoiignore"
else
    ok "__append_pipe_fzf.fish not in rendered .chezmoiignore"
fi
```

- [ ] **Step 6: Run tests**

```bash
make test-unit 2>&1 | tail -3
bash -n tests/integration.sh && echo syntax-ok
git status --short
```
Expected: `# ok`; `syntax-ok`; status shows no unexpected changes (in particular no runtime rewrite of `home/.chezmoiignore` beyond Step 3's edit).

- [ ] **Step 7: Commit**

```bash
git add home/.chezmoiignore home/.chezmoiremove tests/fish/fisher_chezmoi_test.fish \
  tests/fish/fisher_cold_install_test.fish tests/integration.sh
git commit -m "feat(chezmoi): render fisher ignore block from fisher's record

.chezmoiignore is now a template reading _fisher_*_files at render time,
replacing the fish_postexec hook that rewrote the checked-in file. The
hook is removed from targets via .chezmoiremove. Non-fisher generated
files (chezmoi/swamp completions, fish_frozen_key_bindings) are static.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Nudge toward data on `fisher install|remove`

**Files:**
- Modify: `home/private_dot_config/private_fish/conf.d/chezmoi_nudge.fish`
- Test: `tests/fish/chezmoi_nudge_test.fish`

**Interfaces:**
- Consumes: data key `fish_plugins` (Task 2) — referenced only in the message text.
- Produces: `__chezmoi_nudge "fisher install x"` writes `chezmoi?: hx <src>/.chezmoidata.toml (fish_plugins)` to stderr.

- [ ] **Step 1: Point the test at the repo copy and add failing tests**

In `tests/fish/chezmoi_nudge_test.fish`, replace line 5:
```fish
set -l _source_err (source ~/.config/fish/conf.d/chezmoi_nudge.fish 2>&1)
```
with:
```fish
set -g _repo_root (path resolve (status dirname)/../..)
set -l _source_err (source $_repo_root/home/private_dot_config/private_fish/conf.d/chezmoi_nudge.fish 2>&1)
```

Append at end of file:
```fish
# ── Branch 3: fish plugins live in chezmoi data ───────────────────────────────

@echo "Branch 3: fisher install/remove nudges toward .chezmoidata.toml"

@test "fisher install triggers data nudge" \
    (string match -q '*.chezmoidata.toml*' (__chezmoi_nudge "fisher install foo/bar" 2>&1) && echo yes || echo no) = yes

@test "fisher remove triggers data nudge" \
    (string match -q '*.chezmoidata.toml*' (__chezmoi_nudge "fisher remove foo/bar" 2>&1) && echo yes || echo no) = yes

@test "fisher update does not trigger" \
    (string match -q 'chezmoi?:*' (__chezmoi_nudge "fisher update" 2>&1) && echo yes || echo no) = no

@test "fisher list does not trigger" \
    (string match -q 'chezmoi?:*' (__chezmoi_nudge "fisher list" 2>&1) && echo yes || echo no) = no
```

- [ ] **Step 2: Run to verify they fail**

Run: `fish -c 'fishtape tests/fish/chezmoi_nudge_test.fish' 2>&1 | rg '^not ok'`
Expected: `not ok` for the two "triggers data nudge" tests only.

- [ ] **Step 3: Add the branch**

In `chezmoi_nudge.fish`, insert before `return $prev_status`:

```fish
    # Branch 3: plugin nudge — the plugin list lives in .chezmoidata.toml
    if string match -rq '^fisher\s+(install|remove)\b' -- $cmd
        if test -n "$__chezmoi_src"
            echo "chezmoi?: hx $__chezmoi_src/.chezmoidata.toml (fish_plugins)" >&2
        end
    end

```

- [ ] **Step 4: Run tests, deploy, commit**

```bash
make test-unit 2>&1 | tail -3
chezmoi apply ~/.config/fish/conf.d/chezmoi_nudge.fish
git add home/private_dot_config/private_fish/conf.d/chezmoi_nudge.fish tests/fish/chezmoi_nudge_test.fish
git commit -m "feat(fish): nudge to .chezmoidata.toml on fisher install/remove

Tests now source the repo copy instead of the deployed one.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
Expected: `# ok` before committing.

---

### Task 5: Container tier checks a fresh install

**Files:**
- Delete: `tests/fish/container/fisher_sync_test.fish` (uncommitted; tests the retired hook)
- Create: `tests/fish/container/fresh_install_test.fish`
- Commit (already modified, uncommitted): `Makefile`, `Dockerfile` (`ENV CHEZMOI_TEST_CONTAINER=1`, CMD), `CLAUDE.md`
- Modify: `Makefile` (`test-container` also runs the cold-install test), `CLAUDE.md`

**Interfaces:**
- Consumes: data key `fish_plugins` (Task 2); retired hook path (Task 3).

- [ ] **Step 1: Replace the container test**

```bash
trash tests/fish/container/fisher_sync_test.fish
```

Create `tests/fish/container/fresh_install_test.fish`:

```fish
#!/usr/bin/env fish
# Fresh-machine checks after `chezmoi init --apply` in the smoke container.
# Run: make test-smoke (invokes make test-container in the container)

@echo "guard: disposable container"

# Both signals required: the env var alone could leak into a host shell.
set -l in_container (set -q CHEZMOI_TEST_CONTAINER; and test -f /.dockerenv; and echo yes; or echo no)
@test "running inside the smoke container" \
    $in_container = yes
test $in_container = yes; or exit 1

# ── plugins installed from data ───────────────────────────────────────────────

@echo "fresh install: fish plugins from .chezmoidata.toml"

set -l data_plugins (chezmoi execute-template '{{ range .fish_plugins }}{{ . }}{{ "\n" }}{{ end }}')

@test "data lists plugins" \
    (count $data_plugins) -gt 0

for p in $data_plugins
    @test "$p installed by fisher" \
        (contains -- (string lower -- $p) (string lower -- $_fisher_plugins) && echo yes || echo no) = yes
end

@test "fish_plugins unchanged by fisher update" \
    (chezmoi diff --no-pager ~/.config/fish/fish_plugins </dev/null 2>&1 | count) = 0

@test "no pending chezmoi changes under ~/.config/fish" \
    (chezmoi status ~/.config/fish </dev/null 2>&1 | count) = 0

@test "retired sync hook not deployed" \
    (test -e ~/.config/fish/conf.d/fisher_chezmoi_sync.fish && echo yes || echo no) = no
```

- [ ] **Step 2: Run the cold-install test in the container too**

In `Makefile`, change the `test-container` recipe to:
```make
test-container:
	fish -c 'fishtape tests/fish/container/*.fish tests/fish/fisher_cold_install_test.fish'
```

- [ ] **Step 3: Verify the guard on the host**

Run: `make test-container 2>&1 | rg 'not ok 1 running inside'`
Expected: one match (guard refuses on host). Then `git status --short` — no new changes from the run.

- [ ] **Step 4: Run the smoke build**

```bash
make test-smoke > "$TMPDIR/smoke.log" 2>&1; echo "exit=$?"
rg -n '^(FAIL|not ok)|# (pass|fail)' "$TMPDIR/smoke.log"
rg -n 'fisher update|Installed .* plugin' "$TMPDIR/smoke.log" | head
```
(Use the session scratchpad as `$TMPDIR`.) Expected: `exit=0`; no `FAIL:` or `not ok`; the build log shows script 06 installing all eleven plugins. The `packages` stage rebuilds (script 02 changed), so this takes several minutes. `cargo binstall exited 86` in the log is a known, out-of-scope issue.

- [ ] **Step 5: Update CLAUDE.md**

In `CLAUDE.md`, in the "Test tiers" section, replace the sentence beginning `Anything that mutates goes in` with:

```markdown
Fresh-machine and mutating checks go in `tests/fish/container/` (`make test-container`),
which runs only via `make test-smoke` and guards on `CHEZMOI_TEST_CONTAINER` plus
`/.dockerenv`.
```

Append a new section after "Read-only chezmoi queries for ignore state":

```markdown
## fisher is orchestrated by chezmoi

- Plugin list: `fish_plugins` in `.chezmoidata.toml`. `~/.config/fish/fish_plugins` is
  rendered from it; add plugins there, not with `fisher install` (the nudge hook says so).
- `run_onchange_after_06-fish-plugins` runs `fisher update` after deploy. `fisher update`
  writes the file back in file order, so data spelling must match fisher's canonical form.
- `.chezmoiignore` is a template: fisher-owned paths come from `_fisher_*_files` via
  `output "fish" "-c" ...`. `fish --no-config` does not load universal variables, so the
  template must use plain `fish -c`.
- `.chezmoiremove` errors with `inconsistent state` while the source file still exists:
  delete the source file in the same change.
```

- [ ] **Step 6: Commit**

```bash
git add Makefile Dockerfile CLAUDE.md tests/fish/container/fresh_install_test.fish
git commit -m "test(smoke): container tier checks fresh-machine fisher install

make test-container runs inside the smoke image only (guarded by
CHEZMOI_TEST_CONTAINER and /.dockerenv) and asserts plugins from data
are installed, fish_plugins round-trips through fisher, and nothing is
pending under ~/.config/fish.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Roll out on this machine

**Files:** none changed.

- [ ] **Step 1: Review the pending apply**

```bash
chezmoi diff --no-pager </dev/null | rg '^diff --git' 
```
Expected entries: `conf.d/fisher_chezmoi_sync.fish` (deleted), scripts `02-install-packages` and `06-fish-plugins`. No `fish_plugins` content diff. Stop and report if anything else appears.

- [ ] **Step 2: Apply**

```bash
chezmoi apply
```
Script 02 re-runs (brew/cargo/uv installs, idempotent); script 06 runs `fisher update` (network).

- [ ] **Step 3: Verify**

```bash
make test-unit 2>&1 | tail -3
chezmoi status ~/.config/fish
test -e ~/.config/fish/conf.d/fisher_chezmoi_sync.fish && echo STILL-THERE || echo removed
git -C ~/.local/share/chezmoi status --short
```
Expected: `# ok`; empty status; `removed`; clean tree.

- [ ] **Step 4: Other machines**

On every other machine, roll out with `chezmoi update` (pull and apply together) and do not run `fisher install|remove` between pulling and applying: until apply removes it, the old hook would rewrite the templated `.chezmoiignore` in the source.

On every machine, after applying, `exec fish` (or close) every open fish shell: shells started before the rollout still have the old hook loaded in memory, and it fires on `fisher install|update|remove`.

## Out of scope

- Pinning plugin versions (fisher installs from GitHub HEAD) and brew versions.
- `cargo binstall exited 86` seen in the smoke build.

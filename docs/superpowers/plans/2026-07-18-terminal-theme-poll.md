# Terminal Theme Poll (systemd timer) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `fish_prompt`-triggered Windows-registry poll (which blocks every interactive prompt for ~80-90ms via WSL interop process spawn) with a systemd `--user` timer that polls independently of the interactive shell and pushes changes straight into the existing `terminal_theme` universal variable.

**Architecture:** A new autoloaded fish function `__terminal_theme_poll_sync` (pure orchestration, parametrized by target uvar name and query command for testability) is invoked by a thin executable script from a systemd `--user` oneshot service, itself triggered by a systemd `--user` timer with `OnUnitInactiveSec=15s` (guarantees a 15s idle gap between runs regardless of how long any individual `reg.exe` call takes, and systemd's unit-name singleton semantics prevent overlapping runs of the same unit without extra configuration). The existing `__terminal_theme_apply --on-variable terminal_theme` handler (already in `conf.d/terminal_theme.fish`) reacts automatically when the poller writes a changed value — no interactive-path code needed at all once this lands. The old `fish_prompt`-bound `__terminal_theme_sync`/`__terminal_theme_on_prompt` cache-file-based approach is deleted.

**Tech Stack:** fish 4.8, fishtape (test runner, already a fisher plugin in this repo), systemd `--user` units, chezmoi `run_onchange_` scripts for the daemon-reload/enable side effect.

## Global Constraints

- Every new/changed fish function must be covered by a fishtape test using the existing `tests/fish/*_test.fish` conventions (source the file, `@test` assertions) — no untested behavior.
- Do not duplicate `__terminal_theme_query` or `__terminal_theme_parse` — both already exist in `home/private_dot_config/private_fish/conf.d/terminal_theme.fish` and are auto-sourced for non-interactive `fish` invocations too (verified: `conf.d/` sources regardless of interactivity). Reuse them as-is.
- The new poll function must accept the target universal-variable name and the query command as arguments (not hardcode `terminal_theme` or `reg.exe`), so tests never touch the real `terminal_theme` uvar and never require `reg.exe`/WSL to be present.
- `chezmoi` source-tree conventions in this repo: `private_dot_config/` maps to `~/.config/`; `executable_` prefix on a filename sets the executable bit; `run_onchange_NN-name.sh.tmpl` scripts embed a content hash (via `{{ include (joinPath .chezmoi.sourceDir ...) | sha256sum }}`) in a comment so chezmoi re-runs the script only when the hashed file(s) actually change — see `home/.chezmoiscripts/run_onchange_02-install-packages.sh.tmpl:3` for the exact pattern.
- All `run_onchange_*.sh.tmpl` scripts in this repo use `#!/bin/bash` + `set -eufo pipefail` and gate on tool availability with `command -v <tool> &>/dev/null` before using it — no OS-name branching where a direct capability check is possible (per this user's global CLAUDE.md: test for the capability, don't branch on assumed platform).
- `Makefile`'s `test-unit` target explicitly lists every fishtape test file — new test files must be added there or they silently never run in CI/local `make test-unit`.

---

## File Structure

- **Modify** `home/private_dot_config/private_fish/conf.d/terminal_theme.fish` — remove `__terminal_theme_sync` and `__terminal_theme_on_prompt` (the `fish_prompt` hook and its cache-file logic); keep `__terminal_theme_parse`, `__terminal_theme_query`, `__terminal_theme_bat_name`, `__terminal_theme_vivid_name`, `__terminal_theme_apply` unchanged.
- **Modify** `tests/fish/terminal_theme_test.fish` — remove the "Sync: cache reads and terminal_theme updates" and "Integration: background job refreshes cache" sections (they test functions that no longer exist); keep every other section unchanged.
- **Create** `home/private_dot_config/private_fish/functions/__terminal_theme_poll_sync.fish` — the one new function, autoloaded (one-function-per-file, matching this repo's existing `functions/` convention), parametrized for testability.
- **Create** `tests/fish/terminal_theme_poll_test.fish` — fishtape tests for `__terminal_theme_poll_sync`, following the exact source-and-`@test` convention already used by every file in `tests/fish/`.
- **Create** `home/private_dot_config/private_fish/scripts/executable_terminal-theme-poll.fish` — thin executable entrypoint invoked by systemd; wires the real dependencies (`terminal_theme`, `__terminal_theme_query`) into `__terminal_theme_poll_sync`.
- **Create** `home/private_dot_config/systemd/user/terminal-theme-poll.service` — oneshot unit running the entrypoint script, with `TimeoutStartSec` so a wedged `reg.exe` doesn't starve future ticks.
- **Create** `home/private_dot_config/systemd/user/terminal-theme-poll.timer` — `OnUnitInactiveSec=15s` timer triggering the service.
- **Create** `home/.chezmoiscripts/run_onchange_05-terminal-theme-timer.sh.tmpl` — `daemon-reload` + `enable --now` the timer, re-running only when the two unit files' hashed content changes.
- **Modify** `Makefile` — add `tests/fish/terminal_theme_poll_test.fish` to the `test-unit` target's fishtape invocation.

---

### Task 1: `__terminal_theme_poll_sync` function + tests

**Files:**
- Create: `home/private_dot_config/private_fish/functions/__terminal_theme_poll_sync.fish`
- Test: `tests/fish/terminal_theme_poll_test.fish`

**Interfaces:**
- Produces: `__terminal_theme_poll_sync <var_name> <query_cmd...>` — a fish function. `var_name` is the literal name of a universal variable to write (e.g. `terminal_theme`, or a scratch name in tests). `query_cmd...` is the remainder of `$argv`, invoked as a command whose stdout must be exactly `light`, `dark`, or `unknown` (matching `__terminal_theme_parse`'s output contract from `conf.d/terminal_theme.fish`). Sets `$var_name` via `set -U` only when the query result differs from the variable's current value and is not `unknown`. Returns 1 (and does not write) when the query result is `unknown`; returns 0 otherwise.

- [ ] **Step 1: Write the failing tests**

Create `tests/fish/terminal_theme_poll_test.fish`:

```fish
#!/usr/bin/env fish
# Tests for __terminal_theme_poll_sync (systemd-invoked polling → uvar push)
# Run: fishtape tests/fish/terminal_theme_poll_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _src $_repo_root/home/private_dot_config/private_fish/functions/__terminal_theme_poll_sync.fish

set -l _source_err (source $_src 2>&1)

@test "__terminal_theme_poll_sync.fish sources without error" \
    (count $_source_err) = 0

# ── poll_sync: writes only on change, never on unknown ─────────────────────

@echo "poll_sync: writes and no-ops"

set -Ue _test_theme

@test "sets var to light when query returns light" \
    (set -Ue _test_theme; __terminal_theme_poll_sync _test_theme echo light; echo $_test_theme) = light

@test "sets var to dark when query returns dark" \
    (set -Ue _test_theme; __terminal_theme_poll_sync _test_theme echo dark; echo $_test_theme) = dark

@test "updates var when query result differs from current value" \
    (set -U _test_theme light; __terminal_theme_poll_sync _test_theme echo dark; echo $_test_theme) = dark

@test "leaves var unchanged when query result matches current value" \
    (set -U _test_theme dark; __terminal_theme_poll_sync _test_theme echo dark; echo $_test_theme) = dark

@test "does not write when query returns unknown" \
    (set -U _test_theme light; __terminal_theme_poll_sync _test_theme echo unknown; echo $_test_theme) = light

@test "returns 1 when query returns unknown" \
    (set -U _test_theme light; __terminal_theme_poll_sync _test_theme echo unknown; echo $status) = 1

@test "returns 0 when query returns a known value" \
    (set -Ue _test_theme; __terminal_theme_poll_sync _test_theme echo light; echo $status) = 0

set -Ue _test_theme
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `fish -c 'fishtape tests/fish/terminal_theme_poll_test.fish'`
Expected: FAIL — `__terminal_theme_poll_sync: Unknown command` (function does not exist yet).

- [ ] **Step 3: Write the implementation**

Create `home/private_dot_config/private_fish/functions/__terminal_theme_poll_sync.fish`:

```fish
# Impure: run $query_cmd (argv[2..]), write result into the $var_name uvar
# iff the value changed and is not "unknown". Both the target variable name
# and the query command are parameters (not hardcoded) so this is testable
# without reg.exe/WSL and without mutating the real terminal_theme uvar.
# The real caller (scripts/executable_terminal-theme-poll.fish) passes
# terminal_theme and __terminal_theme_query (conf.d/terminal_theme.fish).
function __terminal_theme_poll_sync -a var_name
    set -l query_cmd $argv[2..]
    set -l new_theme ($query_cmd)

    if test "$new_theme" = unknown
        return 1
    end

    if test "$$var_name" = "$new_theme"
        return 0
    end

    set -U $var_name $new_theme
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `fish -c 'fishtape tests/fish/terminal_theme_poll_test.fish'`
Expected: PASS, all 8 assertions.

- [ ] **Step 5: Commit**

```bash
git add home/private_dot_config/private_fish/functions/__terminal_theme_poll_sync.fish tests/fish/terminal_theme_poll_test.fish
git commit -m "feat(fish): add __terminal_theme_poll_sync for out-of-band theme polling"
```

---

### Task 2: Executable entrypoint script

**Files:**
- Create: `home/private_dot_config/private_fish/scripts/executable_terminal-theme-poll.fish`

**Interfaces:**
- Consumes: `__terminal_theme_poll_sync <var_name> <query_cmd...>` (Task 1); `__terminal_theme_query` (existing, `conf.d/terminal_theme.fish` — auto-sourced for this non-interactive invocation, confirmed by direct test: `fish somescript.fish` sources `conf.d/*.fish` regardless of interactivity).
- Produces: an executable file at chezmoi destination `~/.config/fish/scripts/terminal-theme-poll.fish`, invocable standalone (`fish ~/.config/fish/scripts/terminal-theme-poll.fish` or directly as `~/.config/fish/scripts/terminal-theme-poll.fish` once the executable bit is set) with no arguments. Exit code mirrors `__terminal_theme_poll_sync`'s.

- [ ] **Step 1: Write the script**

Create `home/private_dot_config/private_fish/scripts/executable_terminal-theme-poll.fish`:

```fish
#!/usr/bin/env fish
# Invoked by terminal-theme-poll.service (systemd --user timer); not sourced
# by interactive shells and not in a fish autoload directory. Polls the
# Windows registry via __terminal_theme_query (conf.d/terminal_theme.fish,
# auto-sourced for this non-interactive invocation too) and pushes into the
# terminal_theme uvar on change. __terminal_theme_apply (--on-variable
# terminal_theme, same file) reacts automatically — no interactive-path
# code is involved in this update at all.
__terminal_theme_poll_sync terminal_theme __terminal_theme_query
```

`executable_` in the chezmoi source filename sets the executable bit on apply — matches the convention already used by `home/private_dot_config/private_fish/executable_config.fish`.

- [ ] **Step 2: Verify it runs standalone (manual check, WSL required)**

Run:
```bash
chmod +x home/private_dot_config/private_fish/scripts/executable_terminal-theme-poll.fish
fish home/private_dot_config/private_fish/scripts/executable_terminal-theme-poll.fish
echo "exit: $status"
fish -c 'echo $terminal_theme'
```
Expected: exit 0 (or 1 only if `reg.exe` is genuinely unavailable/returns something unparseable — acceptable, matches `__terminal_theme_poll_sync`'s documented contract), and `terminal_theme` reflects the live Windows setting.

- [ ] **Step 3: Commit**

```bash
git add home/private_dot_config/private_fish/scripts/executable_terminal-theme-poll.fish
git commit -m "feat(fish): add systemd-invoked terminal theme poll entrypoint"
```

---

### Task 3: Remove the old `fish_prompt`-bound polling from `terminal_theme.fish`

**Files:**
- Modify: `home/private_dot_config/private_fish/conf.d/terminal_theme.fish`
- Modify: `tests/fish/terminal_theme_test.fish`

**Interfaces:**
- Consumes: nothing new.
- Produces: `conf.d/terminal_theme.fish` retains `__terminal_theme_parse`, `__terminal_theme_query`, `__terminal_theme_bat_name`, `__terminal_theme_vivid_name`, `__terminal_theme_apply` — unchanged signatures, still consumed by Task 2's `__terminal_theme_query` reuse and by the pre-existing `--on-variable terminal_theme` reactivity.

- [ ] **Step 1: Remove the two functions**

In `home/private_dot_config/private_fish/conf.d/terminal_theme.fish`, delete this block (currently lines 23-37, immediately after `__terminal_theme_query`):

```fish
# Impure: read cache → update terminal_theme if changed → fire background refresh
# Accepts cache path as argument for testability
function __terminal_theme_sync
    set -l cache $argv[1]
    if test -f $cache
        set -l theme (string trim (cat $cache))
        if test "$theme" != "$terminal_theme"
            set -g terminal_theme $theme
        end
    end
    __terminal_theme_query > $cache &
end

# Event handler: called on each prompt, uses real cache path
function __terminal_theme_on_prompt --on-event fish_prompt
    __terminal_theme_sync ~/.cache/terminal_theme
end
```

The file should now read, in full:

```fish
# Pure: parse raw reg.exe output → light | dark | unknown
function __terminal_theme_parse
    set -l matches (string match -r '0x(\w+)' -- $argv)
    switch $matches[2]
        case 1
            echo light
        case 0
            echo dark
        case '*'
            echo unknown
    end
end

# Impure: query Windows registry, print result to stdout
function __terminal_theme_query
    __terminal_theme_parse (reg.exe query \
        "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" \
        /v AppsUseLightTheme 2>/dev/null)
end

# Pure: bat theme name for light|dark, respects BAT_THEME_LIGHT/BAT_THEME_DARK overrides
function __terminal_theme_bat_name -a theme
    switch $theme
        case light
            set -q BAT_THEME_LIGHT && echo $BAT_THEME_LIGHT || echo GitHub
        case dark
            set -q BAT_THEME_DARK && echo $BAT_THEME_DARK || echo Dracula
    end
end

# Pure: vivid theme name for light|dark, respects VIVID_THEME_LIGHT/VIVID_THEME_DARK overrides
function __terminal_theme_vivid_name -a theme
    switch $theme
        case light
            set -q VIVID_THEME_LIGHT && echo $VIVID_THEME_LIGHT || echo one-light
        case dark
            set -q VIVID_THEME_DARK && echo $VIVID_THEME_DARK || echo dracula
    end
end

# Effect: apply BAT_THEME and LS_COLORS whenever terminal_theme changes
function __terminal_theme_apply --on-variable terminal_theme
    switch $terminal_theme
        case light dark
            set -gx BAT_THEME (__terminal_theme_bat_name $terminal_theme)
            set -gx LS_COLORS (vivid generate (__terminal_theme_vivid_name $terminal_theme))
    end
end
```

- [ ] **Step 2: Remove the now-invalid tests**

In `tests/fish/terminal_theme_test.fish`, delete the two sections that test the removed functions — everything from the `# ── Sync: reads cache, updates terminal_theme ──` comment through the `rm -f $_cache` line (currently lines 42-70 inclusive):

```fish
# ── Sync: reads cache, updates terminal_theme ─────────────────────────────────

@echo "Sync: cache reads and terminal_theme updates"

set -g _cache (mktemp)

@test "sync sets terminal_theme to light when cache contains light" \
    (echo light > $_cache; set -ge terminal_theme; __terminal_theme_sync $_cache; echo $terminal_theme) = light

@test "sync sets terminal_theme to dark when cache contains dark" \
    (echo dark > $_cache; set -ge terminal_theme; __terminal_theme_sync $_cache; echo $terminal_theme) = dark

@test "sync updates terminal_theme when cached value differs" \
    (echo dark > $_cache; set -g terminal_theme light; __terminal_theme_sync $_cache; echo $terminal_theme) = dark

@test "sync leaves terminal_theme unchanged when cached value matches" \
    (echo light > $_cache; set -g terminal_theme light; __terminal_theme_sync $_cache; echo $terminal_theme) = light

@test "sync leaves terminal_theme unchanged when cache file is absent" \
    (rm -f $_cache; set -g terminal_theme light; __terminal_theme_sync $_cache; echo $terminal_theme) = light

# ── Integration: background job refreshes cache ───────────────────────────────

@echo "Integration: background job writes valid theme to cache"

@test "background query writes light or dark to cache within 500ms" \
    (rm -f $_cache; __terminal_theme_sync $_cache; sleep 0.5; string match -qr '^(light|dark)$' (cat $_cache 2>/dev/null); and echo yes; or echo no) = yes

rm -f $_cache
```

Everything else in the file (parse tests, bat/vivid name tests, apply tests) stays exactly as-is.

- [ ] **Step 3: Run the updated test file**

Run: `fish -c 'fishtape tests/fish/terminal_theme_test.fish'`
Expected: PASS, all remaining assertions (parse, bat_name, vivid_name, apply sections).

- [ ] **Step 4: Confirm the prompt hook is gone**

Run: `fish -c 'source home/private_dot_config/private_fish/conf.d/terminal_theme.fish; functions --handlers-type fish_prompt'`
Expected: no `__terminal_theme_on_prompt` in the output.

- [ ] **Step 5: Commit**

```bash
git add home/private_dot_config/private_fish/conf.d/terminal_theme.fish tests/fish/terminal_theme_test.fish
git commit -m "fix(fish): remove blocking fish_prompt registry poll"
```

---

### Task 4: systemd `--user` unit files

**Files:**
- Create: `home/private_dot_config/systemd/user/terminal-theme-poll.service`
- Create: `home/private_dot_config/systemd/user/terminal-theme-poll.timer`

**Interfaces:**
- Consumes: `~/.config/fish/scripts/terminal-theme-poll.fish` (Task 2's chezmoi destination path).
- Produces: two units, source-controlled, installed by chezmoi at `~/.config/systemd/user/terminal-theme-poll.{service,timer}`, activated in Task 5.

- [ ] **Step 1: Write the service unit**

Create `home/private_dot_config/systemd/user/terminal-theme-poll.service`:

```ini
[Unit]
Description=Poll Windows registry for light/dark theme, push into fish terminal_theme uvar

[Service]
Type=oneshot
TimeoutStartSec=10s
ExecStart=%h/.config/fish/scripts/terminal-theme-poll.fish
```

`TimeoutStartSec=10s` bounds a wedged `reg.exe`/interop call — systemd SIGTERMs it rather than leaving the unit `activating` forever, which would otherwise starve every future timer tick (unit-name singleton semantics mean a second start is coalesced into an already-`activating` unit, not queued).

- [ ] **Step 2: Write the timer unit**

Create `home/private_dot_config/systemd/user/terminal-theme-poll.timer`:

```ini
[Unit]
Description=Periodic trigger for terminal-theme-poll.service

[Timer]
OnBootSec=5s
OnUnitInactiveSec=15s

[Install]
WantedBy=timers.target
```

`OnUnitInactiveSec=15s` (measured from when the service last went *inactive*, i.e. 15s after the previous run *finished*) guarantees a clean idle gap between runs regardless of how long any individual `reg.exe` call takes — unlike `OnUnitActiveSec`, which measures from start time and produces bursty/coalesced re-triggers if a run overruns the interval.

- [ ] **Step 3: Validate unit syntax**

Run: `systemd-analyze --user verify home/private_dot_config/systemd/user/terminal-theme-poll.service home/private_dot_config/systemd/user/terminal-theme-poll.timer`
Expected: no output (no errors). `systemd-analyze verify` accepts arbitrary file paths, not just installed units.

- [ ] **Step 4: Commit**

```bash
git add home/private_dot_config/systemd/user/terminal-theme-poll.service home/private_dot_config/systemd/user/terminal-theme-poll.timer
git commit -m "feat(systemd): add user timer for out-of-band terminal theme polling"
```

---

### Task 5: chezmoi `run_onchange_` activation script

**Files:**
- Create: `home/.chezmoiscripts/run_onchange_05-terminal-theme-timer.sh.tmpl`

**Interfaces:**
- Consumes: `home/private_dot_config/systemd/user/terminal-theme-poll.{service,timer}` (Task 4) — hashed via chezmoi's `include`/`sha256sum` template functions so the script re-runs exactly when those files' content changes, per the pattern at `home/.chezmoiscripts/run_onchange_02-install-packages.sh.tmpl:3`.
- Produces: on machines with a working `systemd --user` session, `terminal-theme-poll.timer` is reloaded and enabled+started; on machines without one (macOS, containers without a user session), the script no-ops without failing `chezmoi apply`.

- [ ] **Step 1: Write the script**

Create `home/.chezmoiscripts/run_onchange_05-terminal-theme-timer.sh.tmpl`:

```bash
#!/bin/bash
set -eufo pipefail

# unit files: {{ include (joinPath .chezmoi.sourceDir "private_dot_config" "systemd" "user" "terminal-theme-poll.service") | sha256sum }} {{ include (joinPath .chezmoi.sourceDir "private_dot_config" "systemd" "user" "terminal-theme-poll.timer") | sha256sum }}

if command -v systemctl &>/dev/null && systemctl --user status &>/dev/null; then
    systemctl --user daemon-reload
    systemctl --user enable --now terminal-theme-poll.timer
fi
```

The `systemctl --user status` probe (rather than branching on `.chezmoi.os`) is a direct capability check: it succeeds only when a real user systemd session is reachable (fails cleanly on macOS with no systemd, and in containers without a user session/dbus), so the script degrades to a no-op instead of failing `chezmoi apply` on unsupported machines.

- [ ] **Step 2: Verify the onchange hash actually changes on edit**

Run:
```bash
chezmoi execute-template < home/.chezmoiscripts/run_onchange_05-terminal-theme-timer.sh.tmpl | head -3
```
Note the hash line. Touch either unit file (e.g. add a trailing blank line to `terminal-theme-poll.timer`), re-run the same command, and confirm the hash line differs. Revert the trailing blank line afterward.

- [ ] **Step 3: Dry-run against a fresh persistent state**

Per this repo's `CLAUDE.md`, use a real (non-`mktemp`-created) boltdb path so the dry-run doesn't silently fall back to real state:
```bash
touch /tmp/fresh-terminal-theme.boltdb
chezmoi apply --persistent-state /tmp/fresh-terminal-theme.boltdb --dry-run --verbose 2>&1 | grep -i terminal-theme
trash /tmp/fresh-terminal-theme.boltdb
```
Expected: the run_onchange script and both unit files appear as pending changes.

- [ ] **Step 4: Apply for real and confirm activation**

Run:
```bash
chezmoi apply
systemctl --user status terminal-theme-poll.timer
```
Expected: timer shown as `active (waiting)`, next elapse within 15s of last trigger.

- [ ] **Step 5: Commit**

```bash
git add home/.chezmoiscripts/run_onchange_05-terminal-theme-timer.sh.tmpl
git commit -m "feat(chezmoi): enable terminal theme poll timer on unit-file change"
```

---

### Task 6: Wire into `Makefile` test suite and confirm no regression

**Files:**
- Modify: `Makefile`

**Interfaces:**
- Consumes: `tests/fish/terminal_theme_poll_test.fish` (Task 1).
- Produces: `make test-unit` runs the new test file alongside every existing one.

- [ ] **Step 1: Add the new test file to `test-unit`**

In `Makefile`, change:

```makefile
test-unit:
	fish -c 'fishtape tests/fish/chezmoi_nudge_test.fish \
	         tests/fish/fisher_chezmoi_test.fish \
	         tests/fish/fisher_cold_install_test.fish \
	         tests/fish/git_extras_test.fish \
	         tests/fish/terminal_theme_test.fish'
```

to:

```makefile
test-unit:
	fish -c 'fishtape tests/fish/chezmoi_nudge_test.fish \
	         tests/fish/fisher_chezmoi_test.fish \
	         tests/fish/fisher_cold_install_test.fish \
	         tests/fish/git_extras_test.fish \
	         tests/fish/terminal_theme_test.fish \
	         tests/fish/terminal_theme_poll_test.fish'
```

- [ ] **Step 2: Run the full unit suite**

Run: `make test-unit`
Expected: PASS across all six test files, including both `terminal_theme_test.fish` (post-Task-3 edits) and the new `terminal_theme_poll_test.fish`.

- [ ] **Step 3: Commit**

```bash
git add Makefile
git commit -m "test: run terminal_theme_poll_test in test-unit target"
```

---

### Task 7: End-to-end verification — confirm the interactive path is actually fast now

**Files:** none (verification only).

**Interfaces:** none.

- [ ] **Step 1: Confirm no event handlers remain on the interactive path**

Run: `fish -c 'functions --handlers'`
Expected: no `__terminal_theme_on_prompt` anywhere in the output (compare against the original list from this conversation's investigation, which had it under `fish_prompt`).

- [ ] **Step 2: Re-measure the postexec+prompt cycle**

Run (same technique used earlier in this investigation):
```fish
fish -c '
set -l t0 (date +%s%N)
echo hi >/dev/null
set -l t1 (date +%s%N)
echo "postexec+prompt path total: "(math "($t1 - $t0) / 1000000")"ms" >&2
'
```
Expected: within noise of the ~1.8ms baseline measured for the handler-less cycle earlier in this conversation, not the ~80-93ms measured for the old `__terminal_theme_sync` call.

- [ ] **Step 3: Confirm the poll loop still keeps the theme fresh**

Run:
```bash
fish -c 'echo $terminal_theme'
```
Toggle the Windows theme (Settings → Colors → choose light/dark), wait up to 15s, then re-run the same command.
Expected: `terminal_theme` reflects the new setting within one timer interval, and `echo $BAT_THEME` / `echo $LS_COLORS` have updated accordingly (confirms `__terminal_theme_apply`'s `--on-variable` reactivity still fires from an externally-pushed uvar write, not just from `set -g` inside the same process).

- [ ] **Step 4: No commit** (verification-only task; if any check fails, return to the relevant earlier task rather than patching here).

---

## Self-Review

**Spec coverage:**
- Fish script location (`~/.config/fish/scripts/`, chezmoi-managed) → Task 2. ✓
- Systemd units at `~/.config/systemd/user/`, chezmoi-managed, no root-depth paths → Task 4. ✓
- `run_onchange_` activation closing the daemon-reload/enable gap → Task 5. ✓
- Parametric `__terminal_theme_poll_sync` (var name + query command as arguments, testable without `reg.exe`) → Task 1. ✓
- `OnUnitInactiveSec` vs `OnUnitActiveSec` distinction and `TimeoutStartSec` hang protection → Task 4. ✓
- No stacking / systemd singleton semantics → structural (default unit behavior), explicitly checked in Task 4 Step 1 comment and verifiable via Task 7. ✓
- Removal of the old blocking `fish_prompt` hook and its tests → Task 3. ✓
- Reuse of `__terminal_theme_query`/`__terminal_theme_parse` instead of duplicating → enforced in Global Constraints, realized in Tasks 1-2. ✓
- Regression-free existing test suite + new test wired into `make test-unit` → Task 6. ✓
- Empirical confirmation the interactive path is actually fast now (the original ask) → Task 7. ✓

**Placeholder scan:** none found — every step has literal file content or literal commands with expected output.

**Type/name consistency:** `__terminal_theme_poll_sync <var_name> <query_cmd...>` signature is identical across Task 1 (definition + tests), Task 2 (real invocation with `terminal_theme __terminal_theme_query`), and the Interfaces block of both tasks. `terminal-theme-poll.service`/`.timer` names match between Task 4 (definition) and Task 5 (`systemctl ... enable --now terminal-theme-poll.timer`). Chezmoi destination path `~/.config/fish/scripts/terminal-theme-poll.fish` matches between Task 2 (Interfaces) and Task 4's `ExecStart=%h/.config/fish/scripts/terminal-theme-poll.fish`.

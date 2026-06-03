# Chezmoi Package Nudge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two non-blocking print-only nudges in fish: one that prompts "add to all machines?" after package manager installs, and one that reminds to run `chezmoi apply` after editing a chezmoiscript.

**Architecture:** A single `fish_postexec` event handler in a new `conf.d/` file. Branch 1 is purely lexical (string match on `$argv[1]`, no subprocesses). Branch 2 matches editor commands on `.chezmoiscripts/` paths then calls `chezmoi status` to confirm a pending run exists. The script rename (`-py` → `-uv`) is independent and goes first.

**Tech Stack:** fish shell, fishtape (test runner), chezmoi

---

## File Structure

| Action | Path |
|---|---|
| Rename | `home/.chezmoiscripts/run_onchange_install-py.sh.tmpl` → `run_onchange_install-uv.sh.tmpl` |
| Create | `home/private_dot_config/private_fish/conf.d/chezmoi_nudge.fish` |
| Create | `tests/fish/chezmoi_nudge_test.fish` |

---

## Task 1: Rename install-py → install-uv

**Files:**
- Rename: `home/.chezmoiscripts/run_onchange_install-py.sh.tmpl` → `home/.chezmoiscripts/run_onchange_install-uv.sh.tmpl`

- [ ] **Step 1: Rename via git mv**

```bash
git mv home/.chezmoiscripts/run_onchange_install-py.sh.tmpl \
       home/.chezmoiscripts/run_onchange_install-uv.sh.tmpl
```

- [ ] **Step 2: Verify**

```bash
ls home/.chezmoiscripts/
```

Expected output includes `run_onchange_install-uv.sh.tmpl`, no `run_onchange_install-py.sh.tmpl`.

- [ ] **Step 3: Commit**

```bash
git commit -m "chore(chezmoi): rename install-py script to install-uv"
```

---

## Task 2: Write failing tests

**Files:**
- Create: `tests/fish/chezmoi_nudge_test.fish`

The test file sources the (not yet existing) nudge function from its deployed location and calls `__chezmoi_nudge` directly, capturing stderr. Branch 1 tests are pure string matching. Branch 2 tests only the negative trigger path (path not containing `.chezmoiscripts/`), since the positive path depends on live `chezmoi status` output.

- [ ] **Step 1: Create test file**

```fish
#!/usr/bin/env fish
# Tests for chezmoi package nudge hook
# Run: fishtape tests/fish/chezmoi_nudge_test.fish

source ~/.config/fish/conf.d/chezmoi_nudge.fish 2>/dev/null

# ── Branch 1: install nudge triggers ─────────────────────────────────────────

@echo "Branch 1: install nudge triggers on known package managers"

@test "brew install triggers nudge" \
    (string match -q 'chezmoi?:*' (__chezmoi_nudge "brew install bat" 2>&1) && echo yes || echo no) = yes

@test "brew install with flags triggers nudge" \
    (string match -q 'chezmoi?:*' (__chezmoi_nudge "brew install --cask bat" 2>&1) && echo yes || echo no) = yes

@test "cargo install triggers nudge" \
    (string match -q 'chezmoi?:*' (__chezmoi_nudge "cargo install delta" 2>&1) && echo yes || echo no) = yes

@test "cargo binstall triggers nudge" \
    (string match -q 'chezmoi?:*' (__chezmoi_nudge "cargo binstall delta" 2>&1) && echo yes || echo no) = yes

@test "uv tool install triggers nudge" \
    (string match -q 'chezmoi?:*' (__chezmoi_nudge "uv tool install ruff" 2>&1) && echo yes || echo no) = yes

# ── Branch 1: maintenance commands do not trigger ─────────────────────────────

@echo "Branch 1: maintenance commands produce no nudge"

@test "brew upgrade does not trigger" \
    (string match -q 'chezmoi?:*' (__chezmoi_nudge "brew upgrade bat" 2>&1) && echo yes || echo no) = no

@test "brew uninstall does not trigger" \
    (string match -q 'chezmoi?:*' (__chezmoi_nudge "brew uninstall bat" 2>&1) && echo yes || echo no) = no

@test "cargo update does not trigger" \
    (string match -q 'chezmoi?:*' (__chezmoi_nudge "cargo update" 2>&1) && echo yes || echo no) = no

@test "uv tool upgrade does not trigger" \
    (string match -q 'chezmoi?:*' (__chezmoi_nudge "uv tool upgrade ruff" 2>&1) && echo yes || echo no) = no

@test "bare uv install (without tool) does not trigger" \
    (string match -q 'chezmoi?:*' (__chezmoi_nudge "uv install ruff" 2>&1) && echo yes || echo no) = no

# ── Branch 2: editor on non-chezmoi path produces no apply reminder ───────────

@echo "Branch 2: editor on non-chezmoiscripts path produces no output"

@test "editor on regular config file produces no apply reminder" \
    (string match -q '*chezmoi apply*' (__chezmoi_nudge "hx ~/.config/fish/config.fish" 2>&1) && echo yes || echo no) = no

@test "non-editor command with chezmoiscripts in path produces no apply reminder" \
    (string match -q '*chezmoi apply*' (__chezmoi_nudge "cat .chezmoiscripts/run_onchange_install-brew.sh.tmpl" 2>&1) && echo yes || echo no) = no
```

- [ ] **Step 2: Run tests — expect failure (function not defined)**

```bash
fish -c 'fishtape tests/fish/chezmoi_nudge_test.fish'
```

Expected: all tests fail with `__chezmoi_nudge: Unknown command`.

---

## Task 3: Implement the nudge function

**Files:**
- Create: `home/private_dot_config/private_fish/conf.d/chezmoi_nudge.fish`

- [ ] **Step 1: Create the function file**

```fish
function __chezmoi_nudge --on-event fish_postexec
    set -l prev_status $status
    set -l cmd $argv[1]

    # Branch 1: install nudge — lexical match only, no subprocesses
    if string match -rq '\b(install|binstall)\b' -- $cmd
        and string match -rq '^(brew|cargo)\s|^uv\s+tool\s' -- $cmd
        set -l src (chezmoi source-path 2>/dev/null)
        if test -n "$src"
            echo "chezmoi?: hx $src/.chezmoiscripts/" >&2
        end
    end

    # Branch 2: apply reminder — fires only when editor opened a chezmoiscript
    if string match -rq '^\s*(hx|vim|nvim|nano)\s' -- $cmd
        and string match -q '*.chezmoiscripts/*' -- $cmd
        if chezmoi status 2>/dev/null | string match -rq '^\s*R.*chezmoiscripts'
            echo "chezmoi: script changes pending → chezmoi apply" >&2
        end
    end

    return $prev_status
end
```

Save to: `home/private_dot_config/private_fish/conf.d/chezmoi_nudge.fish`

- [ ] **Step 2: Deploy to live config so tests can source it**

```bash
chezmoi apply ~/.config/fish/conf.d/chezmoi_nudge.fish
```

Expected: `~/.config/fish/conf.d/chezmoi_nudge.fish` now exists.

---

## Task 4: Verify tests pass and commit

**Files:**
- No changes — verification only, then commit both Task 2 and Task 3 files.

- [ ] **Step 1: Run the test suite**

```bash
fish -c 'fishtape tests/fish/chezmoi_nudge_test.fish'
```

Expected output:
```
TAP version 13
# Branch 1: install nudge triggers on known package managers
ok 1 brew install triggers nudge
ok 2 brew install with flags triggers nudge
ok 3 cargo install triggers nudge
ok 4 cargo binstall triggers nudge
ok 5 uv tool install triggers nudge
# Branch 1: maintenance commands produce no nudge
ok 6 brew upgrade does not trigger
ok 7 brew uninstall does not trigger
ok 8 cargo update does not trigger
ok 9 uv tool upgrade does not trigger
ok 10 bare uv install (without tool) does not trigger
# Branch 2: editor on non-chezmoiscripts path produces no output
ok 11 editor on regular config file produces no apply reminder
ok 12 non-editor command with chezmoiscripts in path produces no apply reminder

1..12
# pass 12
# ok
```

- [ ] **Step 2: Smoke-test branch 1 in a live shell**

```bash
fish -c '__chezmoi_nudge "brew install bat"'
```

Expected stderr: `chezmoi?: hx /home/orion/.local/share/chezmoi/.chezmoiscripts/`

- [ ] **Step 3: Commit**

```bash
git add home/private_dot_config/private_fish/conf.d/chezmoi_nudge.fish \
        tests/fish/chezmoi_nudge_test.fish
git commit -m "feat(shell): add chezmoi package nudge fish hook"
```

#!/usr/bin/env fish
# Tests for chezmoi package nudge hook
# Run: fishtape tests/fish/chezmoi_nudge_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -l _source_err (source $_repo_root/home/private_dot_config/private_fish/conf.d/chezmoi_nudge.fish 2>&1)

@test "chezmoi_nudge.fish sources without stderr" \
    (count $_source_err) = 0

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

@test "apt install does not trigger" \
    (string match -q 'chezmoi?:*' (__chezmoi_nudge "apt install bat" 2>&1) && echo yes || echo no) = no

@test "pip install does not trigger" \
    (string match -q 'chezmoi?:*' (__chezmoi_nudge "pip install requests" 2>&1) && echo yes || echo no) = no

# ── Branch 2: editor on non-chezmoi path produces no apply reminder ───────────

@echo "Branch 2: editor on non-chezmoiscripts path produces no output"

@test "editor on regular config file produces no apply reminder" \
    (string match -q '*chezmoi apply*' (__chezmoi_nudge "hx ~/.config/fish/config.fish" 2>&1) && echo yes || echo no) = no

@test "non-editor command with chezmoiscripts in path produces no apply reminder" \
    (string match -q '*chezmoi apply*' (__chezmoi_nudge "cat .chezmoiscripts/run_onchange_install-brew.sh.tmpl" 2>&1) && echo yes || echo no) = no

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

#!/usr/bin/env fish
# Tests for chezmoi package nudge hook
# Run: fishtape tests/fish/chezmoi_nudge_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -l _source_err (source $_repo_root/home/private_dot_config/private_fish/conf.d/chezmoi_nudge.fish 2>&1)

@test "chezmoi_nudge.fish sources without stderr" \
    (count $_source_err) = 0

# ── Branch 1: install nudge triggers ─────────────────────────────────────────

@echo "Branch 1: install nudge triggers on known package managers"

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

# ── Branch 1: maintenance commands do not trigger ─────────────────────────────

@echo "Branch 1: maintenance commands produce no nudge"

@test "brew upgrade does not trigger" \
    (string match -q 'chezmoi?:*' (__chezmoi_nudge "brew upgrade bat" 2>&1) && echo yes || echo no) = no

@test "brew uninstall suggests pkg usage" \
    "$(__chezmoi_nudge_task 'brew uninstall bat')" = $_pkg_usage

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

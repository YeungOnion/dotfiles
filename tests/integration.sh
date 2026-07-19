#!/bin/bash
# Integration test: verify system state after each chezmoi init phase.
# Runs in the smoke Docker target (all phases complete) but assertions are
# grouped by the phase that produces each state, for documentation clarity.
set -uo pipefail

fail=0
ok()     { echo "ok: $*"; }
check_fail() { echo "FAIL: $*"; fail=1; }

# ── after packages phase ──────────────────────────────────────────────────────

echo "# packages phase"

for tool in fish bat jj cargo uv; do
    if command -v "$tool" &>/dev/null; then
        ok "$tool in PATH"
    else
        check_fail "$tool not in PATH"
    fi
done

# chezmoi state must record both bootstrap and install-packages
for script in "01-bootstrap-package-managers" "02-install-packages"; do
    if chezmoi state dump 2>/dev/null \
            | jq -e --arg s "$script" \
              '.scriptState // {} | to_entries[].value.name | select(contains($s))' \
            &>/dev/null; then
        ok "$script recorded in chezmoi state"
    else
        check_fail "$script not recorded in chezmoi state"
    fi
done

# ── after post-install phase ──────────────────────────────────────────────────

echo "# post-install phase"

if [[ $(uname) == "Linux" ]]; then
    if [[ -L "$HOME/.local/bin/bat" ]]; then
        ok "~/.local/bin/bat is a symlink"
    else
        check_fail "~/.local/bin/bat is not a symlink"
    fi
fi

editor=$(fish -c 'echo $EDITOR' 2>/dev/null)
if [[ "$editor" == "hx" ]]; then
    ok "EDITOR universal var is hx"
else
    check_fail "EDITOR universal var is '${editor}' (expected hx)"
fi

bat_dark=$(fish -c 'echo $BAT_THEME_DARK' 2>/dev/null)
if [[ "$bat_dark" == "Dracula" ]]; then
    ok "BAT_THEME_DARK universal var is Dracula"
else
    check_fail "BAT_THEME_DARK universal var is '${bat_dark}' (expected Dracula)"
fi

# ── after dotfiles phase ──────────────────────────────────────────────────────

echo "# dotfiles phase"

for f in \
    "$HOME/.config/fish/aliases.fish" \
    "$HOME/.config/fish/config.fish" \
    "$HOME/.config/fish/fish_plugins" \
    "$HOME/.config/fish/conf.d/fisher_chezmoi_sync.fish" \
    "$HOME/.config/fish/functions/__terminal_theme_poll_sync.fish" \
    "$HOME/.config/fish/scripts/terminal-theme-poll.fish" \
    "$HOME/.config/systemd/user/terminal-theme-poll.service" \
    "$HOME/.config/systemd/user/terminal-theme-poll.timer"; do
    if [[ -f "$f" ]]; then
        ok "${f/$HOME/~} deployed"
    else
        check_fail "${f/$HOME/~} not deployed"
    fi
done

# terminal-theme-poll.fish must be executable (systemd invokes it directly)
poll_script="$HOME/.config/fish/scripts/terminal-theme-poll.fish"
if [[ -x "$poll_script" ]]; then
    ok "terminal-theme-poll.fish is executable"
else
    check_fail "terminal-theme-poll.fish is not executable"
fi

# 05-terminal-theme-timer must be recorded in chezmoi state, same as other scripts
if chezmoi state dump 2>/dev/null \
        | jq -e '.scriptState // {} | to_entries[].value.name | select(contains("05-terminal-theme-timer"))' \
        &>/dev/null; then
    ok "05-terminal-theme-timer recorded in chezmoi state"
else
    check_fail "05-terminal-theme-timer not recorded in chezmoi state"
fi

# fish must start without stderr
stderr=$(fish -c exit 2>&1)
if [[ -z "$stderr" ]]; then
    ok "fish starts without stderr"
else
    check_fail "fish starts with stderr: $stderr"
fi

# chezmoiignore must have fisher block
chezmoi_src=$(chezmoi source-path 2>/dev/null)
chezmoiignore="$chezmoi_src/.chezmoiignore"
if grep -qF '# fisher:begin' "$chezmoiignore" 2>/dev/null; then
    ok "fisher:begin block in .chezmoiignore"
else
    check_fail "fisher:begin block missing from .chezmoiignore"
fi

if awk '/^# fisher:begin/{p=1;next} /^# fisher:end/{p=0} p && NF' \
        "$chezmoiignore" 2>/dev/null | grep -q .; then
    ok "fisher ignore block is non-empty"
else
    check_fail "fisher ignore block is empty"
fi

# user-managed function must not appear in fisher ignore block
if awk '/^# fisher:begin/{p=1;next} /^# fisher:end/{p=0} p' "$chezmoiignore" \
        | grep -qF '__append_pipe_fzf.fish'; then
    check_fail "__append_pipe_fzf.fish incorrectly in fisher ignore block"
else
    ok "__append_pipe_fzf.fish not in fisher ignore block"
fi

exit $fail

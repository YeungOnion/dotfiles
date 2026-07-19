#!/usr/bin/env fish
# Tests for __terminal_theme_poll_sync (systemd-invoked polling → uvar push)
# Run: fishtape tests/fish/terminal_theme_poll_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _src $_repo_root/home/private_dot_config/private_fish/functions/__terminal_theme_poll_sync.fish

set -l _source_err (source $_src 2>&1)

@test "__terminal_theme_poll_sync.fish sources without error" \
    (count $_source_err) = 0

# ── poll_sync: writes and no-ops ─────────────────────────────────

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

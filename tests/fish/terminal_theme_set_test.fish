#!/usr/bin/env fish
# Tests for terminal_theme / __terminal_theme_set (command-line and script setter)
# Run: fishtape tests/fish/terminal_theme_set_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _fn $_repo_root/home/private_dot_config/private_fish/functions

set -l _source_err (source $_fn/__terminal_theme_set.fish 2>&1; source $_fn/terminal_theme.fish 2>&1)

@test "setter files source without error" \
    (count $_source_err) = 0

# ── __terminal_theme_set: against a test uvar, never terminal_theme ──────────

@echo "__terminal_theme_set: set and print"

set -Ue _test_theme

@test "sets light" \
    (set -Ue _test_theme; __terminal_theme_set _test_theme light >/dev/null; echo $_test_theme) = light

@test "sets dark" \
    (set -U _test_theme light; __terminal_theme_set _test_theme dark >/dev/null; echo $_test_theme) = dark

@test "writes a universal, not a global" \
    (set -Ue _test_theme; __terminal_theme_set _test_theme dark >/dev/null; set -qU _test_theme; echo $status) = 0

@test "prints the new value" \
    (set -U _test_theme light; __terminal_theme_set _test_theme dark) = dark

@test "no action prints the current value" \
    (set -U _test_theme dark; __terminal_theme_set _test_theme) = dark

@test "no action prints unknown when unset" \
    (set -Ue _test_theme; __terminal_theme_set _test_theme) = unknown

@test "no action prints unknown for a value that is neither light nor dark" \
    (set -U _test_theme garbage; __terminal_theme_set _test_theme) = unknown

@echo "__terminal_theme_set: toggle"

@test "toggle light → dark" \
    (set -U _test_theme light; __terminal_theme_set _test_theme toggle >/dev/null; echo $_test_theme) = dark

@test "toggle dark → light" \
    (set -U _test_theme dark; __terminal_theme_set _test_theme toggle >/dev/null; echo $_test_theme) = light

@test "toggle from unset → light" \
    (set -Ue _test_theme; __terminal_theme_set _test_theme toggle >/dev/null; echo $_test_theme) = light

@echo "__terminal_theme_set: writes only on change"

function _count_writes --on-variable _test_theme
    set -g _writes (math $_writes + 1)
end

@test "setting the current value does not fire --on-variable" \
    (set -U _test_theme dark; set -g _writes 0; __terminal_theme_set _test_theme dark >/dev/null; echo $_writes) = 0

@test "changing the value fires --on-variable once" \
    (set -U _test_theme dark; set -g _writes 0; __terminal_theme_set _test_theme light >/dev/null; echo $_writes) = 1

functions -e _count_writes

@echo "__terminal_theme_set: bad action"

@test "bad action returns 2" \
    (set -U _test_theme dark; __terminal_theme_set _test_theme purple 2>/dev/null; echo $status) = 2

@test "bad action leaves the value" \
    (set -U _test_theme dark; __terminal_theme_set _test_theme purple 2>/dev/null; echo $_test_theme) = dark

@test "bad action prints usage to stderr" \
    (set -U _test_theme dark; __terminal_theme_set _test_theme purple 2>&1 >/dev/null | string match -q 'usage:*'; echo $status) = 0

set -Ue _test_theme

# ── terminal_theme: read-only paths only (setting would change the live uvar) ─

@echo "terminal_theme: arguments"

@test "terminal_theme with no argument prints light, dark or unknown" \
    (contains -- (terminal_theme) light dark unknown; echo $status) = 0

@test "terminal_theme with two arguments returns 2" \
    (terminal_theme light dark 2>/dev/null; echo $status) = 2

@test "terminal_theme with a bad argument returns 2" \
    (terminal_theme purple 2>/dev/null; echo $status) = 2

@test "terminal_theme delegates to __terminal_theme_set for terminal_theme" \
    (functions terminal_theme | string match -q '*__terminal_theme_set terminal_theme $argv*'; echo $status) = 0

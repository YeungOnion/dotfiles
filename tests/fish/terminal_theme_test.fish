#!/usr/bin/env fish
# Tests for terminal theme detection from Windows registry
# Run: fishtape tests/fish/terminal_theme_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _src $_repo_root/home/private_dot_config/private_fish/conf.d/terminal_theme.fish

set -l _source_err (source $_src 2>&1)

@test "terminal_theme.fish sources without error" \
    (count $_source_err) = 0

# ── Parse: pure logic, no IO ──────────────────────────────────────────────────

@echo "Registry output parsing"

set -l _light_reg "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize
    AppsUseLightTheme    REG_DWORD    0x1
"
set -l _dark_reg "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize
    AppsUseLightTheme    REG_DWORD    0x0
"

@test "parses full light registry output as light" \
    (__terminal_theme_parse $_light_reg) = light

@test "parses full dark registry output as dark" \
    (__terminal_theme_parse $_dark_reg) = dark

@test "parses bare 0x1 as light" \
    (__terminal_theme_parse "0x1") = light

@test "parses bare 0x0 as dark" \
    (__terminal_theme_parse "0x0") = dark

@test "returns unknown for empty input" \
    (__terminal_theme_parse "") = unknown

@test "returns unknown for unrecognised value" \
    (__terminal_theme_parse "garbage") = unknown

@test "query prints unknown when reg.exe is missing" \
    (__terminal_theme_query /nonexistent/reg.exe 2>&1) = unknown

# ── Theme name mapping: pure logic ────────────────────────────────────────────

@echo "bat theme name mapping"

@test "bat name for light returns BAT_THEME_LIGHT when set" \
    (set -g BAT_THEME_LIGHT SentinelLight; __terminal_theme_bat_name light) = SentinelLight

@test "bat name for dark returns BAT_THEME_DARK when set" \
    (set -g BAT_THEME_DARK SentinelDark; __terminal_theme_bat_name dark) = SentinelDark

@echo "vivid theme name mapping"

@test "vivid name for light returns VIVID_THEME_LIGHT when set" \
    (set -g VIVID_THEME_LIGHT solarized-light; __terminal_theme_vivid_name light) = solarized-light

@test "vivid name for dark returns VIVID_THEME_DARK when set" \
    (set -g VIVID_THEME_DARK nord; __terminal_theme_vivid_name dark) = nord

@test "vivid name for light falls back to one-light when VIVID_THEME_LIGHT unset" \
    (set -ge VIVID_THEME_LIGHT; __terminal_theme_vivid_name light) = one-light

@test "vivid name for dark falls back to dracula when VIVID_THEME_DARK unset" \
    (set -ge VIVID_THEME_DARK; __terminal_theme_vivid_name dark) = dracula

# ── Apply: on-variable effect ─────────────────────────────────────────────────

@echo "Apply: on-variable sets BAT_THEME and LS_COLORS"

# Pin overrides to sentinels so tests are independent of user universal vars
set -g BAT_THEME_LIGHT SentinelLight
set -g BAT_THEME_DARK SentinelDark
set -ge VIVID_THEME_LIGHT; set -ge VIVID_THEME_DARK

@test "BAT_THEME set to BAT_THEME_LIGHT when terminal_theme becomes light" \
    (set -g terminal_theme dark; set -g terminal_theme light; echo $BAT_THEME) = SentinelLight

@test "BAT_THEME set to BAT_THEME_DARK when terminal_theme becomes dark" \
    (set -g terminal_theme light; set -g terminal_theme dark; echo $BAT_THEME) = SentinelDark

@test "LS_COLORS non-empty when terminal_theme becomes light" \
    (set -g terminal_theme dark; set -ge LS_COLORS; set -g terminal_theme light; test -n "$LS_COLORS"; and echo yes; or echo no) = yes

@test "LS_COLORS non-empty when terminal_theme becomes dark" \
    (set -g terminal_theme light; set -ge LS_COLORS; set -g terminal_theme dark; test -n "$LS_COLORS"; and echo yes; or echo no) = yes

@test "apply does nothing for unknown terminal_theme" \
    (set -g terminal_theme light; set -g BAT_THEME before; set -g terminal_theme unknown; echo $BAT_THEME) = before

@echo "claude theme name mapping"

@test "claude name for light falls back to light" \
    (set -ge CLAUDE_THEME_LIGHT; __terminal_theme_claude_name light) = light

@test "claude name for dark falls back to dark" \
    (set -ge CLAUDE_THEME_DARK; __terminal_theme_claude_name dark) = dark

@test "claude name for light returns CLAUDE_THEME_LIGHT when set" \
    (set -g CLAUDE_THEME_LIGHT light-daltonized; __terminal_theme_claude_name light) = light-daltonized

@test "claude name for dark returns CLAUDE_THEME_DARK when set" \
    (set -g CLAUDE_THEME_DARK dark-ansi; __terminal_theme_claude_name dark) = dark-ansi

@test "claude name for anything else is empty" \
    (count (__terminal_theme_claude_name unknown)) = 0

set -ge CLAUDE_THEME_LIGHT; set -ge CLAUDE_THEME_DARK

# ── claude wrapper: theme per launch via --settings ──────────────────────────

@echo "claude wrapper"

source (status dirname)/helpers/terminal_theme_env.fish

# a stub that prints its arguments; the real claude must never run here
mkdir -p $_root/bin
printf '#!/bin/sh\nfor a in "$@"; do printf "%%s\\n" "$a"; done\n' >$_root/bin/claude
chmod +x $_root/bin/claude
set -g _stub "set -x PATH $_root/bin \$PATH;"

function _claude_args --description 'run the wrapper on hello world in the temp env, args on one line'
    _tt "$_stub $argv[1] claude hello world" | string join ' '
end

set -g _resolves (_tt "$_stub command -v claude")

@test "the stub claude resolves first" \
    "$_resolves" = $_root/bin/claude

if test "$_resolves" = $_root/bin/claude
    _fresh
    @test "with no theme published there is no --settings" \
        (_claude_args '') = 'hello world'

    _tt 'terminal_theme light'
    @test "with light published the theme is passed first" \
        (_claude_args '') = '--settings {"theme":"light"} hello world'

    _tt 'terminal_theme dark'
    @test "with dark published the theme is passed first" \
        (_claude_args '') = '--settings {"theme":"dark"} hello world'

    @test "an override name is passed" \
        (_claude_args 'set -x CLAUDE_THEME_DARK dark-ansi;') = '--settings {"theme":"dark-ansi"} hello world'

    @test "an override that would break the JSON is not passed" \
        (_claude_args 'set -x CLAUDE_THEME_DARK \'x"y\';' 2>/dev/null) = 'hello world'

    @test "an override that would break the JSON is reported" \
        (_tt "$_stub set -x CLAUDE_THEME_DARK 'x\"y'; claude hello" 2>&1 >/dev/null | string match -q '*x"y*'; echo $status) = 0
else
    @echo "skipped wrapper tests: the stub does not resolve first"
end

unlink $_root/bin/claude 2>/dev/null
_teardown

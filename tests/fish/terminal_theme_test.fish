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

#!/usr/bin/env fish
# Tests for __terminal_theme_poll_sync (systemd-invoked polling → system state file).
# The poller records what Windows says; it never changes the target or the universal.
# Run: fishtape tests/fish/terminal_theme_poll_test.fish

source (status dirname)/helpers/terminal_theme_env.fish

set -l _fn $_fish_src/functions
set -l _source_err (for f in __terminal_theme_poll_sync __terminal_theme_read __terminal_theme_write
        source $_fn/$f.fish 2>&1
    end)

@test "poll_sync sources without error" \
    (count $_source_err) = 0

# ── poll_sync: records the system state ─────────────────────────

@echo "poll_sync: writes the system file"

set -g _sys $_root/poll/system

@test "records light" \
    (__terminal_theme_poll_sync $_sys echo light; cat $_sys) = light

@test "records dark" \
    (__terminal_theme_poll_sync $_sys echo dark; cat $_sys) = dark

@test "returns 0 after recording a known value" \
    (__terminal_theme_poll_sync $_sys echo light; echo $status) = 0

# a write replaces the file (temp + mv), so an unchanged inode means no write
@test "an unchanged value does not rewrite the file" \
    (__terminal_theme_poll_sync $_sys echo dark; set -l i (stat -c %i $_sys)
     __terminal_theme_poll_sync $_sys echo dark; test (stat -c %i $_sys) = $i; echo $status) = 0

@test "an unchanged value returns 0" \
    (__terminal_theme_poll_sync $_sys echo dark; __terminal_theme_poll_sync $_sys echo dark; echo $status) = 0

for out in unknown garbage
    @test "does not write when the query prints $out" \
        (__terminal_theme_poll_sync $_sys echo light; __terminal_theme_poll_sync $_sys echo $out; cat $_sys) = light
    @test "returns 1 when the query prints $out" \
        (__terminal_theme_poll_sync $_sys echo $out; echo $status) = 1
end

# A query that fails before printing (reg.exe missing) yields no output, not
# "unknown"; that must not empty the file.
@test "does not write when the query prints nothing" \
    (__terminal_theme_poll_sync $_sys echo light; __terminal_theme_poll_sync $_sys true; cat $_sys) = light

@test "returns 1 when the query prints nothing" \
    (__terminal_theme_poll_sync $_sys true; echo $status) = 1

@echo "poll_sync: never changes the target or the universal"

_fresh
_tt 'terminal_theme dark'

@test "polling light leaves the target dark" \
    (_tt '__terminal_theme_poll_sync (__terminal_theme_state_file system) echo light'; cat (_target_file)) = dark

@test "polling light leaves the universal dark" \
    (_tt '__terminal_theme_poll_sync (__terminal_theme_state_file system) echo light'; _uvar) = dark

@test "polling light records light as the system state" \
    (_tt '__terminal_theme_poll_sync (__terminal_theme_state_file system) echo light'; cat (_system_file)) = light

@test "the poll script records into the system state file" \
    (string match -q '*__terminal_theme_poll_sync (__terminal_theme_state_file system) __terminal_theme_query*' \
        <$_fish_src/scripts/executable_terminal-theme-poll.fish; echo $status) = 0

# ── one writer for the universal ────────────────────────────────

@echo "only __terminal_theme_publish writes the terminal_theme universal"

set -g _theme_files $_fish_src/functions/*terminal_theme*.fish $_fish_src/conf.d/terminal_theme.fish \
    $_fish_src/scripts/*terminal-theme*.fish
set -g _writers (for f in $_theme_files
        string match -qr '^\s*[^#]*\bset\s+(-\w*U\w*|--universal)\b' <$f; and path basename $f
    end)

@test "theme files are found" \
    (count $_theme_files) -gt 5

@test "set -U appears only in __terminal_theme_publish" \
    "$_writers" = __terminal_theme_publish.fish

# ── systemd unit: no PATH lookup ─────────────────────────────────

@echo "systemd unit: no PATH lookup"

set -g _unit $_repo_root/home/private_dot_config/systemd/user/terminal-theme-poll.service

# A PATH rendered at apply time depended on the applying shell (it once
# rendered `.` for reg.exe), so the unit names fish by absolute path.
@test "service unit is static, not a template" \
    (test -f $_unit; and not test -e $_unit.tmpl; echo $status) = 0

@test "service runs the script with fish by absolute path" \
    (string match -rq '^ExecStart=/\S+/fish %h/' <$_unit; echo $status) = 0

@test "service sets no PATH" \
    (string match -q 'Environment=PATH*' <$_unit; echo $status) = 1

_teardown

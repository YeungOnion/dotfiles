#!/usr/bin/env fish
# Tests for the terminal theme target/system state, its effects and the terminal_theme CLI.
# Everything runs in a temp XDG root with a private tmux server (helpers/terminal_theme_env.fish).
# Run: fishtape tests/fish/terminal_theme_state_test.fish

source (status dirname)/helpers/terminal_theme_env.fish

set -l _fn $_fish_src/functions
set -l _source_err (for f in __terminal_theme_state_file __terminal_theme_read __terminal_theme_write
        source $_fn/$f.fish 2>&1
    end)

@test "state helpers source without error" \
    (count $_source_err) = 0

# ── state files: paths, strict read, atomic write ─────────────────────────────

@echo "state file paths"

@test "target path is under XDG_STATE_HOME" \
    (_tt '__terminal_theme_state_file target') = $_root/state/terminal-theme/target

@test "system path is under XDG_STATE_HOME" \
    (_tt '__terminal_theme_state_file system') = $_root/state/terminal-theme/system

@test "without XDG_STATE_HOME the path is under ~/.local/state" \
    (env -u XDG_STATE_HOME fish --no-config -c "source $_fn/__terminal_theme_state_file.fish; __terminal_theme_state_file target") = ~/.local/state/terminal-theme/target

@test "an unknown state name returns 2" \
    (__terminal_theme_state_file other; echo $status) = 2

@echo "read accepts exactly light or dark"

set -g _f $_root/read-probe

@test "reads light" \
    (printf 'light\n' >$_f; __terminal_theme_read $_f) = light

@test "reads dark without a trailing newline" \
    (printf dark >$_f; __terminal_theme_read $_f) = dark

for case in '' 'blue\n' 'garbage\n' 'light\nx\n' ' light \n' '../../x\n'
    @test "rejects '$case' with status 1, no output, no stderr" \
        (printf "$case" >$_f; __terminal_theme_read $_f 2>&1; echo $status) = 1
end

@test "rejects a missing file" \
    (__terminal_theme_read $_root/missing 2>&1; echo $status) = 1

@test "rejects an unreadable file" \
    (printf 'light\n' >$_f; chmod 000 $_f; __terminal_theme_read $_f 2>&1; echo $status; chmod 644 $_f) = 1

@test "rejects a directory" \
    (mkdir -p $_root/dir-probe; __terminal_theme_read $_root/dir-probe 2>&1; echo $status) = 1

@echo "write"

set -g _w $_root/w/sub/target

@test "write creates missing parents with mode 700" \
    (__terminal_theme_write $_w light; stat -c %a (path dirname $_w)) = 700

@test "write stores the word and a newline" \
    (__terminal_theme_write $_w dark; od -c $_w | string collect) = (printf 'dark\n' | od -c | string collect)

@test "written file is mode 644" \
    (__terminal_theme_write $_w light; stat -c %a $_w) = 644

@test "write rejects any other value with status 2" \
    (__terminal_theme_write $_w purple; echo $status) = 2

@test "a rejected value leaves the file unchanged" \
    (__terminal_theme_write $_w dark; __terminal_theme_write $_w purple; cat $_w) = dark

@test "write replaces an unreadable file" \
    (__terminal_theme_write $_w light; chmod 000 $_w; __terminal_theme_write $_w dark; cat $_w) = dark

@test "write leaves no temp file behind" \
    (__terminal_theme_write $_w light; count (path dirname $_w)/*) = 1

set -g _d $_root/w/dirtarget
mkdir -p $_d

@test "write refuses a directory at the path with status 1" \
    (__terminal_theme_write $_d light 2>/dev/null; echo $status) = 1

@test "write puts nothing inside that directory" \
    (__terminal_theme_write $_d light 2>/dev/null; count $_d/*) = 0

@test "write explains the refusal on stderr" \
    (__terminal_theme_write $_d light 2>&1 >/dev/null | string match -q '*directory*'; echo $status) = 0

# ── effects: tmux palette by switch, the only universal writer ────────────────

@echo "tmux palette"

_fresh
_tmux_up

@test "light sources the light palette" \
    (_tt '__terminal_theme_tmux light'; _palette) = light

@test "dark sources the dark palette" \
    (_tt '__terminal_theme_tmux dark'; _palette) = dark

# plant conf files where a path built from the value could land; none may run
for p in $_root/x.conf $_root/cfg/x.conf $_root/cfg/tmux/x.conf
    echo 'set -g @pwned yes' >$p
end

@test "a path-like theme is refused with status 1" \
    (_tt '__terminal_theme_tmux ../../../x' 2>/dev/null; echo $status) = 1

@test "a path-like theme is never sourced" \
    (_tt '__terminal_theme_tmux ../../../x' 2>/dev/null; _tmux show -gqv @pwned; echo end) = end

@test "a refused theme is explained on stderr" \
    (_tt '__terminal_theme_tmux blue' 2>&1 >/dev/null | string match -q '*blue*'; echo $status) = 0

_tmux_down

@test "no tmux server: exit 0, nothing printed" \
    (_tt '__terminal_theme_tmux light' 2>&1; echo $status) = 0

@test "no tmux server: no server is started" \
    (_tt '__terminal_theme_tmux light'; _tmux has-session 2>/dev/null; echo $status) = 1

@echo "publish: the only writer of the terminal_theme universal"

_fresh

@test "publish light sets the universal" \
    (_tt '__terminal_theme_publish light'; _uvar) = light

@test "publish dark sets the universal" \
    (_tt '__terminal_theme_publish dark'; _uvar) = dark

@test "publish refuses other values with status 1" \
    (_tt '__terminal_theme_publish blue'; echo $status) = 1

@test "a refused publish leaves the universal" \
    (_tt '__terminal_theme_publish dark; __terminal_theme_publish blue'; _uvar) = dark

set -g _count 'set -g n 0; function _c --on-variable terminal_theme; set -g n (math $n + 1); end'

@test "publishing the current value fires no --on-variable handler" \
    (_tt '__terminal_theme_publish dark'; _tt "$_count; __terminal_theme_publish dark; echo \$n") = 0

@test "publishing a new value fires the handler once" \
    (_tt '__terminal_theme_publish dark'; _tt "$_count; __terminal_theme_publish light; echo \$n") = 1

_teardown

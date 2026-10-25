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

# ── terminal_theme: the CLI on the target state ───────────────────────────────

function _set_all --description 'target, universal and private-server palette all at $argv[1]'
    _fresh
    _tmux_up
    _tt "__terminal_theme_write (__terminal_theme_state_file target) $argv[1]; __terminal_theme_tmux $argv[1]; __terminal_theme_publish $argv[1]"
end

function _spoil --description 'replace state file $argv[1] with bad data of kind $argv[2]'
    set -l f $argv[1]
    mkdir -p (path dirname $f)
    chmod u+rw $f 2>/dev/null
    test -e $f; and trash $f
    switch $argv[2]
        case blue garbage
            _put $f "$argv[2]\n"
        case empty
            _put $f ''
        case two-lines
            _put $f 'light\nx\n'
        case padded
            _put $f ' light \n'
        case missing
        case unreadable
            _put $f 'light\n'
            chmod 000 $f
        case directory
            mkdir $f
    end
end

function _summary --description 'one line: target content and size, universal, palette'
    set -l f (_target_file)
    set -l t (__terminal_theme_read $f; or echo bad)
    echo "target=$t size="(stat -c %s $f 2>/dev/null)" uvar="(_uvar)" palette="(_palette)
end

function _run --description 'run terminal_theme $argv in the temp env; print summary, warning and status'
    set -l err (_tt "terminal_theme $argv" 2>&1 >/dev/null)
    set -l st $status
    set -l warned no
    string match -q '*reset to dark*' -- $err; and set warned yes
    echo (_summary)" warned=$warned status=$st"
end

@echo "terminal_theme: assignments"

_fresh

@test "light prints nothing" \
    (count (_tt 'terminal_theme light' 2>&1)) = 0

@test "light writes the target" \
    (_tt 'terminal_theme light'; cat (_target_file)) = light

@test "light publishes the universal" \
    (_tt 'terminal_theme light'; _uvar) = light

@test "dark writes the target and publishes" \
    (_tt 'terminal_theme dark'; echo (cat (_target_file)) (_uvar)) = 'dark dark'

@test "no argument prints the target" \
    (_tt 'terminal_theme dark'; _tt terminal_theme) = dark

_tmux_up

@test "light recolors the tmux palette" \
    (_tt 'terminal_theme light'; _palette) = light

@test "dark recolors the tmux palette" \
    (_tt 'terminal_theme dark'; _palette) = dark

_tmux_down

@test "with no tmux server an assignment still exits 0" \
    (_tt 'terminal_theme light'; echo $status) = 0

@test "with no tmux server the target is still written" \
    (_tt 'terminal_theme dark'; cat (_target_file)) = dark

@echo "terminal_theme: toggle and apply"

_fresh

@test "toggle light → dark" \
    (_tt 'terminal_theme light; terminal_theme toggle'; cat (_target_file)) = dark

@test "toggle dark → light" \
    (_tt 'terminal_theme dark; terminal_theme toggle'; cat (_target_file)) = light

@test "apply republishes a stale universal from the target" \
    (_tt 'terminal_theme light; __terminal_theme_publish dark; terminal_theme apply'; _uvar) = light

@echo "terminal_theme: reading bad target data is read-only"

_fresh
_spoil (_target_file) blue

@test "no argument with a bad target prints nothing" \
    (count (_tt terminal_theme 2>&1)) = 0

@test "no argument with a bad target returns 1" \
    (_tt terminal_theme; echo $status) = 1

@test "no argument with a bad target leaves the file" \
    (_tt terminal_theme; cat (_target_file)) = blue

@echo "terminal_theme: bad target data is fixed to dark"

for op in apply toggle
    for kind in blue empty garbage two-lines padded missing unreadable
        _set_all light
        _spoil (_target_file) $kind
        @test "$op fixes a $kind target to dark" \
            (_run $op) = 'target=dark size=5 uvar=dark palette=dark warned=yes status=0'
    end

    # a directory can't be replaced without deleting it: refuse, change nothing
    _set_all light
    _spoil (_target_file) directory
    @test "$op with a directory target fails and changes nothing" \
        (_run $op) = 'target=bad size=4096 uvar=light palette=light warned=yes status=1'
    @test "$op puts nothing inside a directory target" \
        (count (_target_file)/*) = 0
end

@echo "terminal_theme system: bad system data changes nothing"

for kind in blue empty garbage two-lines missing unreadable directory
    _set_all light
    _spoil (_system_file) $kind
    set -l inode (stat -c %i (_target_file))
    @test "system with a $kind system file leaves target, universal and palette" \
        (_run system) = 'target=light size=6 uvar=light palette=light warned=no status=0'
    @test "system with a $kind system file does not rewrite the target" \
        (stat -c %i (_target_file)) = $inode
    @test "system with a $kind system file prints nothing" \
        (count (_tt 'terminal_theme system' 2>&1)) = 0
end

@test "system copies a dark system theme to the target" \
    (_set_all light; _put (_system_file) 'dark\n'; _run system) = 'target=dark size=5 uvar=dark palette=dark warned=no status=0'

@echo "terminal_theme: arguments"

_fresh

@test "a bad argument returns 2" \
    (_tt 'terminal_theme blue' 2>/dev/null; echo $status) = 2

@test "a bad argument prints usage on stderr" \
    (_tt 'terminal_theme blue' 2>&1 >/dev/null | string match -q 'usage:*'; echo $status) = 0

@test "a bad argument writes no target" \
    (_tt 'terminal_theme blue' 2>/dev/null; test -e (_target_file); echo $status) = 1

@test "two arguments return 2" \
    (_tt 'terminal_theme light dark' 2>/dev/null; echo $status) = 2

_teardown

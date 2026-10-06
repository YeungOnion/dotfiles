#!/usr/bin/env fish
# Tests for scratch: argument validation and the tmuxinator invocation
# Run: fishtape tests/fish/scratch_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _src $_repo_root/home/private_dot_config/private_fish/functions/scratch.fish

set -l _source_err (source $_src 2>&1)

@test "scratch.fish sources without error" \
    (count $_source_err) = 0

# Isolate from the real ~/sandbox and never launch tmux: tmuxinator echoes its argv.
set -g _real_home $HOME
set -g _tmp_home (mktemp -d)
set -gx HOME $_tmp_home
set -g _today (date +%y%m%d)
mkdir -p $HOME/sandbox/260101/old $HOME/sandbox/$_today/existing/nested

function tmuxinator
    echo $argv
end

# ── Valid arguments ───────────────────────────────────────────────────────────

@echo "Valid arguments start the scratch project"

@test "no argument opens the latest date dir" \
    "$(scratch)" = "start scratch"

@test "plain name is placed under today" \
    "$(scratch foo)" = "start scratch $_today/foo"

@test "plain name is not created by the function (template does that)" \
    (scratch fresh >/dev/null; test -e $HOME/sandbox/$_today/fresh; and echo yes; or echo no) = no

@test "existing date-prefixed path is sandbox-relative" \
    "$(scratch 260101/old)" = "start scratch 260101/old"

@test "existing bare date dir is accepted" \
    "$(scratch 260101)" = "start scratch 260101"

@test "existing nested path is today-relative" \
    "$(scratch existing/nested)" = "start scratch $_today/existing/nested"

# ── Invalid arguments ─────────────────────────────────────────────────────────

@echo "Invalid arguments fail without launching tmuxinator"

@test "more than one argument fails" \
    (scratch a b 2>/dev/null; echo $status) = 1

@test "more than one argument does not launch" \
    (count (scratch a b 2>/dev/null)) = 0

@test "missing date-prefixed path fails" \
    (scratch 260101/missing 2>/dev/null; echo $status) = 1

@test "missing date dir fails" \
    (scratch 250101 2>/dev/null; echo $status) = 1

@test "date-prefixed name that does not exist fails" \
    (scratch 260101-notes 2>/dev/null; echo $status) = 1

@test "missing nested path fails" \
    (scratch existing/missing 2>/dev/null; echo $status) = 1

@test "missing nested path does not launch" \
    (count (scratch existing/missing 2>/dev/null)) = 0

@test "absolute path fails unless it exists under today" \
    (scratch /tmp 2>/dev/null; echo $status) = 1

@test "invalid argument explains itself on stderr" \
    (string match -q '*does not exist*' (scratch existing/missing 2>&1 >/dev/null); and echo yes; or echo no) = yes

# ── Failure propagation ───────────────────────────────────────────────────────

@echo "Errors from commands propagate"

function tmuxinator
    return 3
end

@test "tmuxinator failure is returned" \
    (scratch foo; echo $status) = 3

function tmuxinator
    echo $argv
end
function date
    return 1
end

@test "date failure fails without launching" \
    (count (scratch foo 2>/dev/null)) = 0

@test "date failure returns non-zero" \
    (scratch foo 2>/dev/null; test $status -ne 0; and echo yes; or echo no) = yes

functions -e date tmuxinator
# trash resolves its trash dir from $HOME, so restore it before cleanup
set -gx HOME $_real_home
trash $_tmp_home

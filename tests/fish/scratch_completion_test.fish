#!/usr/bin/env fish
# Completion for scratch follows its argument rules, independent of the current directory:
# date-prefixed → paths under ~/sandbox; otherwise → existing subdirs of today's dir.
# Run: fishtape tests/fish/scratch_completion_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _real_home $HOME
set -g _tmp_home (mktemp -d)
set -gx HOME $_tmp_home
set -g _today (date +%y%m%d)
mkdir -p $HOME/sandbox/260101/old $HOME/sandbox/260102 $HOME/sandbox/$_today/existing/nested $HOME/sandbox/$_today/other

source $_repo_root/home/private_dot_config/private_fish/completions/scratch.fish
cd /

function _c --description 'completion candidates (without descriptions) for a scratch command line'
    complete -C "scratch $argv[1]" | string split -f1 \t
end

@echo "date-prefixed: paths under ~/sandbox"

@test "date prefix lists matching date dirs" \
    "$(_c 2601)" = "260101/
260102/"

@test "full date dir lists its subdirs" \
    "$(_c 260101/)" = "260101/old/"

@echo "otherwise: existing subdirs of today's dir"

@test "plain prefix lists today's subdirs" \
    "$(_c ex)" = "existing/"

@test "nested path lists deeper subdirs" \
    "$(_c existing/)" = "existing/nested/"

@test "empty argument offers today's subdirs and date dirs" \
    (set -l c (_c ""); contains -- 260101/ $c; and contains -- existing/ $c; and echo yes; or echo no) = yes

@test "no file completion fallback (/bin exists in cwd)" \
    (count (_c bi)) = 0

@test "candidates do not depend on the current directory" \
    (cd /tmp; and _c ex) = "existing/"

cd $_repo_root
set -gx HOME $_real_home
trash $_tmp_home

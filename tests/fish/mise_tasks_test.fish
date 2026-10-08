#!/usr/bin/env fish
# Tests for mise-tasks/* — tasks are pointed at a temp copy of the data and never apply.
# Run: fishtape tests/fish/mise_tasks_test.fish

set -g _repo_root (path resolve (status dirname)/../..)

set -g _task_dirs
function _task_env
    set -l d (mktemp -d)
    set -ga _task_dirs $d
    cp $_repo_root/home/.chezmoidata/*.json $d/
    echo $d
end

function _run --description 'run a mise task against data dir $argv[1]'
    env DOTFILES_DATA_DIR=$argv[1] DOTFILES_NO_APPLY=1 mise -C $_repo_root run $argv[2..-1]
end

set -g _real_before (git -C $_repo_root status --porcelain home/.chezmoidata)

@echo "fish-plugin"

set -l d (_task_env)
@test "fish-plugin add records the plugin" \
    (_run $d fish-plugin add foo/bar >/dev/null 2>&1; jq -r '.fish_plugins[-1]' $d/fish.json) = foo/bar

set -l d (_task_env)
@test "fish-plugin remove drops the plugin" \
    (_run $d fish-plugin remove jethrokuan/z >/dev/null 2>&1; jq -r '.fish_plugins | index("jethrokuan/z")' $d/fish.json) = null

set -l d (_task_env)
@test "fish-plugin rejects a trailing slash" \
    (_run $d fish-plugin add foo/bar/ >/dev/null 2>&1; echo $status) = 1
@test "rejected plugin leaves data unchanged" \
    (cmp -s $d/fish.json $_repo_root/home/.chezmoidata/fish.json && echo same || echo changed) = same

set -l d (_task_env)
@test "fish-plugin rejects an unknown action" \
    (_run $d fish-plugin frob foo/bar >/dev/null 2>&1; echo $status) = 1

# apply failure must surface. This runs the task WITHOUT DOTFILES_NO_APPLY, so the
# chezmoi command is injected: mise prepends its own tool dirs (chezmoi included)
# to PATH inside tasks, so a PATH stub would be bypassed and the real chezmoi run.
set -l d (_task_env)
set -l stub (mktemp -d)
printf '#!/bin/sh\necho "stub-chezmoi $*" >> "$(dirname "$0")/calls"\nexit 7\n' > $stub/chezmoi; chmod +x $stub/chezmoi
@test "apply failure exits non-zero" \
    (env DOTFILES_CHEZMOI=$stub/chezmoi DOTFILES_DATA_DIR=$d mise -C $_repo_root run fish-plugin add foo/bar >/dev/null 2>&1; test $status -ne 0; and echo yes; or echo no) = yes
@test "apply went to the injected chezmoi" \
    (string match -q 'stub-chezmoi apply *' < $stub/calls 2>/dev/null; and echo yes; or echo no) = yes
trash $stub

@echo "real data untouched"

@test "repo data has no new changes" \
    "$(git -C $_repo_root status --porcelain home/.chezmoidata)" = "$_real_before"

# only the directories this test created
trash $_task_dirs

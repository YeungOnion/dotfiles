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
@test "sample plugin is present before removal" \
    (jq -r '.fish_plugins | index("jorgebucaran/autopair.fish") != null' $d/fish.json) = true
@test "fish-plugin remove drops the plugin" \
    (_run $d fish-plugin remove jorgebucaran/autopair.fish >/dev/null 2>&1; jq -r '.fish_plugins | index("jorgebucaran/autopair.fish")' $d/fish.json) = null

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

@echo "pkg"

set -l d (_task_env)
@test "pkg add brew records the package" \
    (_run $d pkg add brew cowsay >/dev/null 2>&1; jq -r '.brew_packages[-1]' $d/packages.json) = cowsay

set -l d (_task_env)
@test "pkg add cargo-plugin strips a cargo- prefix" \
    (_run $d pkg add cargo-plugin cargo-audit >/dev/null 2>&1; jq -r '.cargo_plugins[-1]' $d/packages.json) = audit

set -l d (_task_env)
@test "pkg remove uv drops the package" \
    (_run $d pkg remove uv jrnl >/dev/null 2>&1; jq -r '.uv_packages | index("jrnl")' $d/packages.json) = null

set -l d (_task_env)
@test "unknown manager fails" \
    (_run $d pkg add brw cowsay >/dev/null 2>&1; echo $status) = 1
@test "data unchanged after unknown manager" \
    (cmp -s $d/packages.json $_repo_root/home/.chezmoidata/packages.json && echo same || echo changed) = same

@echo "fish-var"

set -l d (_task_env)
@test "fish-var set records the variable" \
    (_run $d fish-var set FOO_THEME dark >/dev/null 2>&1; jq -r '.fish_universal.FOO_THEME' $d/fish.json) = dark

set -l d (_task_env)
@test "fish-var unset removes the variable" \
    (_run $d fish-var unset EDITOR >/dev/null 2>&1; jq -r '.fish_universal | has("EDITOR")' $d/fish.json) = false

set -l d (_task_env)
@test "fish-var rejects an invalid name" \
    (_run $d fish-var set 1BAD x >/dev/null 2>&1; echo $status) = 1

set -l d (_task_env)
@test "fish-var set without a value fails" \
    (_run $d fish-var set FOO >/dev/null 2>&1; echo $status) = 1

@echo "following the nudge after a manual removal succeeds"

# Applies for real, so everything it touches is a stand-in: chezmoi is a stub,
# universals live in a temp XDG_CONFIG_HOME, brew is a PATH stub (not a mise tool).
set -l ok_chezmoi (mktemp -d)
set -a _task_dirs $ok_chezmoi
printf '#!/bin/sh\nexit 0\n' > $ok_chezmoi/chezmoi; chmod +x $ok_chezmoi/chezmoi

set -l d (_task_env)
set -l xdg (mktemp -d)
set -a _task_dirs $xdg
@test "fish-var unset of an already-erased universal exits 0" \
    (env XDG_CONFIG_HOME=$xdg DOTFILES_CHEZMOI=$ok_chezmoi/chezmoi DOTFILES_DATA_DIR=$d mise -C $_repo_root run fish-var unset EDITOR >/dev/null 2>&1; echo $status) = 0

function _brew_stub --description 'fake brew; $argv[1] = exit status of `brew list`'
    set -l dir (mktemp -d)
    set -ga _task_dirs $dir
    # like real brew: list and uninstall both fail when the package is not installed
    printf '#!/bin/sh\necho "$*" >> "$(dirname "$0")/calls"\ncase "$1" in list|uninstall) exit %s;; *) exit 0;; esac\n' $argv[1] > $dir/brew
    chmod +x $dir/brew
    echo $dir
end

# These reach a real `brew uninstall` unless the stub wins. Resolve brew exactly as a
# task does (mise env + fish --no-config); run them only if the stub is what resolves.
set -l gone (_brew_stub 1)
set -l present (_brew_stub 0)
set -l resolved (env PATH=(string join : $gone $PATH) mise -C $_repo_root exec -- fish --no-config -c 'command -v brew')
@test "stub brew shadows the real one inside tasks" \
    "$resolved" = $gone/brew
if test "$resolved" = $gone/brew
    set -l d (_task_env)
    @test "pkg remove of an already-uninstalled package exits 0" \
        (env PATH=(string join : $gone $PATH) DOTFILES_CHEZMOI=$ok_chezmoi/chezmoi DOTFILES_DATA_DIR=$d mise -C $_repo_root run pkg remove brew bat >/dev/null 2>&1; echo $status) = 0
    @test "pkg remove skips uninstall when the package is not installed" \
        (string match -q 'list *' < $gone/calls; and not string match -q 'uninstall *' < $gone/calls; and echo skipped; or echo wrong) = skipped

    set -l d (_task_env)
    @test "pkg remove uninstalls an installed package" \
        (env PATH=(string join : $present $PATH) DOTFILES_CHEZMOI=$ok_chezmoi/chezmoi DOTFILES_DATA_DIR=$d mise -C $_repo_root run pkg remove brew bat >/dev/null 2>&1; string match -q 'uninstall bat' < $present/calls; and echo called; or echo skipped) = called
end

@echo "real data untouched"

@test "repo data has no new changes" \
    "$(git -C $_repo_root status --porcelain home/.chezmoidata)" = "$_real_before"

# only the directories this test created
trash $_task_dirs

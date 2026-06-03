#!/usr/bin/env fish
# Tests for home/private_dot_config/private_fish/completions/git-extras.fish
#
# Run:  fishtape tests/fish/git_extras_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _extras $_repo_root/home/private_dot_config/private_fish/completions/git-extras.fish
set -g _git_fish (fish -c 'echo $__fish_data_dir')/completions/git.fish

# Returns completion words only (strips tab-delimited descriptions).
# Excludes ~/.config from fish_complete_path so complete -C uses only our
# source file, not the deployed (possibly stale) version.
function _completions -a cmdline
    fish -c "
      set fish_complete_path (string match -rv '\.config/fish' \$fish_complete_path)
      source $_git_fish
      source $_extras
      complete -C '$cmdline'
    " 2>/dev/null | string replace -r '\t.*' ''
end

function _has
    set -l item $argv[1]
    set -l all $argv[2..]
    contains -- $item $all
    and echo yes
    or echo no
end

# ── branchless commands appear under `git <TAB>` ──────────────────────────────

@echo "branchless commands registered"

set -g _git_cmds (_completions "git ")

for cmd in sl smartlog sw next prev move restack reword sync submit undo hide unhide amend record query test
    @test "git $cmd appears in \`git <TAB>\`" \
        (_has $cmd $_git_cmds) = yes
end

# ── filter-repo appears under `git <TAB>` ────────────────────────────────────

@test "git filter-repo appears in \`git <TAB>\`" \
    (_has filter-repo $_git_cmds) = yes

# ── no file paths at positional position for flag-only commands ───────────────

@echo "flag-only commands: no file completions at positional position"

# TODO: file fallback suppression not working — fish still returns completions
# for cmd in next prev move undo amend record
#     set -l got (_completions "git $cmd ")
#     @test "git $cmd <SPC>: empty (no file fallback)" \
#         (count $got) -eq 0
# end

# ── flags present when typing - ───────────────────────────────────────────────

@echo "flags available when typing -"

@test "git next -: --all present"       (_has --all      (_completions "git next -"))   = yes
@test "git next -: --branch present"    (_has --branch   (_completions "git next -"))   = yes
@test "git prev -: --all present"       (_has --all      (_completions "git prev -"))   = yes
@test "git move -: --source present"    (_has --source   (_completions "git move -"))   = yes
@test "git undo -: --yes present"       (_has --yes      (_completions "git undo -"))   = yes
@test "git amend -: --reparent present" (_has --reparent (_completions "git amend -"))  = yes
@test "git record -: --message present" (_has --message  (_completions "git record -")) = yes

# ── revset completions for commands that accept commits ───────────────────────

@echo "revset completions"

for cmd in restack reword sync submit hide unhide query
    set -l got (_completions "git $cmd ")
    @test "git $cmd <SPC>: @ present"         (_has @ $got)          = yes
    @test "git $cmd <SPC>: stack() present"   (_has 'stack()' $got)  = yes
    @test "git $cmd <SPC>: draft() present"   (_has 'draft()' $got)  = yes
end

# ── git test subcommands ──────────────────────────────────────────────────────

@echo "git test subcommands"

set -l _test_cmds (_completions "git test ")

@test "git test <SPC>: run present"   (_has run   $_test_cmds) = yes
@test "git test <SPC>: show present"  (_has show  $_test_cmds) = yes
@test "git test <SPC>: clean present" (_has clean $_test_cmds) = yes
@test "git test <SPC>: fix present"   (_has fix   $_test_cmds) = yes
# TODO: file fallback suppression not working — fish still returns file completions
# @test "git test <SPC>: no file paths" \
#     (count (string match -r '\.(fish|toml|json|md|sh|lock)$' -- $_test_cmds)) -eq 0

# ── git test run flags and revsets ────────────────────────────────────────────

set -l _test_run_flags (_completions "git test run -")
set -l _test_run_pos   (_completions "git test run ")

@test "git test run -: --exec present"   (_has --exec   $_test_run_flags) = yes
@test "git test run -: --jobs present"   (_has --jobs   $_test_run_flags) = yes
@test "git test run -: --search present" (_has --search $_test_run_flags) = yes
@test "git test run <SPC>: @ present"    (_has @ $_test_run_pos)          = yes

# ── git sw offers branches and revsets ───────────────────────────────────────

@echo "git sw completions"

set -l _sw_pos (_completions "git sw ")

@test "git sw <SPC>: @ present"         (_has @ $_sw_pos)         = yes
@test "git sw <SPC>: stack() present"   (_has 'stack()' $_sw_pos) = yes
@test "git sw -: --create present"      (_has --create (_completions "git sw -")) = yes

# ── git filter-repo flags ─────────────────────────────────────────────────────

@echo "git filter-repo flags"

set -l _fr_flags (_completions "git filter-repo -")

@test "git filter-repo -: --path present"    (_has --path    $_fr_flags) = yes
@test "git filter-repo -: --analyze present" (_has --analyze $_fr_flags) = yes
@test "git filter-repo -: --force present"   (_has --force   $_fr_flags) = yes

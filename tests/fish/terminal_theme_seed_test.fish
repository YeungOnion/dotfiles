#!/usr/bin/env fish
# chezmoi seeds the terminal_theme target with dark and never overwrites it
# (create_ prefix). Applies only that target from the real source to a temp
# destination with a fresh state file; the live home and chezmoi state are untouched.
# Run: fishtape tests/fish/terminal_theme_seed_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _tmp (mktemp -d)
set -g _dest $_tmp/home
set -g _target $_dest/.local/state/terminal-theme/target
mkdir -p $_dest

function _apply --description 'apply .local (in the source: only terminal-theme) into the temp destination'
    # a single nested target fails when its parent directories are missing (stat error)
    # umask 022: an agent shell's 0002 would change the modes chezmoi computes
    fish --no-config -c 'umask 022; chezmoi --config $argv[1] --source $argv[2] --destination $argv[3] \
            --persistent-state $argv[4] apply --no-tty $argv[5]' \
        $_repo_root/chezmoi.test.toml $_repo_root/home $_dest $_tmp/state.boltdb $_dest/.local </dev/null
end

@echo "chezmoi seeds the target state"

@test "the first apply succeeds" \
    (_apply; echo $status) = 0

@test "the seeded target is dark" \
    (cat $_target) = dark

@test "the state directory is private (700)" \
    (stat -c %a (path dirname $_target)) = 700

@test "a later apply keeps a changed target" \
    (printf 'light\n' >$_target; _apply; cat $_target) = light

# Deleting a target that changed after chezmoi wrote it makes the next apply ask
# "has changed since chezmoi last wrote it" (no TTY: no answer) instead of re-creating
# it. terminal_theme apply/toggle treat a missing target as bad data and assign dark
# (terminal_theme_state_test.fish), so the seed is only the first-apply default.

trash $_tmp

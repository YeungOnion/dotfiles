#!/usr/bin/env fish
# tmux config load applies the terminal_theme target: theme.conf runs
# `terminal_theme apply` at server start and on every reload, so a reload keeps the
# target instead of re-reading Windows. Private server, temp XDG root (helpers/).
# Run: fishtape tests/fish/tmux_theme_test.fish

source (status dirname)/helpers/terminal_theme_env.fish

set -g _theme_conf $_tmux_src/conf.d/theme.conf

function _tmux_up_theme --description 'start the private server with the real theme.conf and the temp XDG env'
    env -u TMUX XDG_CONFIG_HOME=$_root/cfg XDG_STATE_HOME=$_root/state TMUX_TMPDIR=$_root \
        tmux -f $_theme_conf new-session -d -s t
end

@echo "theme.conf delegates to terminal_theme"

@test "theme.conf runs terminal_theme apply" \
    (string match -q "run-shell 'fish -c \"terminal_theme apply\"'" <$_theme_conf; echo $status) = 0

@test "theme.conf no longer runs tmux-theme-sync" \
    (string match -q '*tmux-theme-sync*' <$_theme_conf; echo $status) = 1

@test "tmux-theme-sync.sh is gone from the source" \
    (test -e $_tmux_src/scripts/executable_tmux-theme-sync.sh; echo $status) = 1

@test "chezmoi removes the deployed tmux-theme-sync.sh" \
    (string match -q '.config/tmux/scripts/tmux-theme-sync.sh' <$_repo_root/home/.chezmoiremove; echo $status) = 0

@echo "server start and reload follow the target"

_fresh
_tt 'terminal_theme light'
_tmux_up_theme

@test "a server started with target light has the light palette" \
    (_palette) = light

@test "a reload restores the target after a manual palette change" \
    (_tmux set -g @thm_theme_name dark; _tmux source-file $_theme_conf; _palette) = light

_fresh
_tt 'terminal_theme dark'
_tmux_up_theme

@test "a server started with target dark has the dark palette" \
    (_palette) = dark

_fresh
_put (_target_file) 'blue\n'
_tmux_up_theme

@test "a server started with a bad target gets the dark palette" \
    (_palette) = dark

@test "a server started with a bad target fixes the file to dark" \
    (cat (_target_file)) = dark

_teardown

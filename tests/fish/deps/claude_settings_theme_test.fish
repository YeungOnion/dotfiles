#!/usr/bin/env fish
# External dependency: does Claude Code honor `theme` passed with --settings?
# The terminal_theme plan sets Claude's theme per process this way (like BAT_THEME),
# so a claude upgrade that ignores it would silently break that.
# Manual only (not in make test-unit): it starts claude, which updates ~/.claude.json
# startup counters. tmux runs as a private server in a temp TMUX_TMPDIR with no config,
# so the live server and tmux.conf are untouched.
# Run: fishtape tests/fish/deps/claude_settings_theme_test.fish

set -g _tmp (mktemp -d)
set -gx TMUX_TMPDIR $_tmp
set -e TMUX
set -g _cwd (path resolve (status dirname)/../../..)

function _render_codes --description 'start claude with --settings theme $argv[1] in session $argv[2], print its distinct SGR codes'
    set -l win $argv[2]
    tmux -f /dev/null new-session -d -s $win -x 120 -y 40 -c $_cwd \
        env COLORTERM=truecolor claude --settings "{\"theme\":\"$argv[1]\"}"
    # wait for colored output, then let the first frame finish
    for i in (seq 40)
        string match -q '*[38;*' -- (tmux capture-pane -e -p -t $win) ; and break
        sleep 0.5
    end
    sleep 2
    tmux capture-pane -e -p -t $win | string match -ar '\e\[[0-9;]*m' | sort -u | string join ' '
end

set -g _dark (_render_codes dark dark)
set -g _dark_again (_render_codes dark dark-again)
set -g _light (_render_codes light light)
tmux kill-server 2>/dev/null

@echo "claude --settings theme"

@test "claude rendered colored output with the dark setting" \
    (string match -q '*38;*' -- $_dark; echo $status) = 0

# control: if one theme renders differently run to run, the next test proves nothing
@test "the same theme renders the same colors twice" \
    (test "$_dark" = "$_dark_again"; echo $status) = 0

@test "theme from --settings changes the rendered colors" \
    (test "$_dark" != "$_light"; echo $status) = 0

trash $_tmp

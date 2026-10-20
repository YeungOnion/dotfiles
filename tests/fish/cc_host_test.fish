#!/usr/bin/env fish
# cc host: a per-machine chezmoi init answer decides whether this machine keeps WSL and
# tmux ready for remote Claude Code sessions (the tmux-cc user service, its enable script).
# Run: fishtape tests/fish/cc_host_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _src $_repo_root/home
set -g _cfg_tmpl $_src/.chezmoi.toml.tmpl
set -g _ignore $_src/.chezmoiignore
set -g _unit $_src/private_dot_config/systemd/user/tmux-cc.service
set -g _script $_src/.chezmoiscripts/run_onchange_after_07-tmux-cc.sh.tmpl
set -g _test_cfg $_repo_root/chezmoi.test.toml
set -g _prompt 'Keep WSL and tmux ready for remote Claude Code sessions on this machine'

set -g _tmp
# a bare config, so this machine's own answers never leak into these renders
set -g _bare_cfg (mktemp --suffix .toml)
set -ga _tmp $_bare_cfg
printf '[data]\n  java_home = ""\n' > $_bare_cfg

function _answer --description 'render the config template (argv: chezmoi flags), read cc_host back as chezmoi would'
    set -l cfg (mktemp --suffix .toml)
    set -ga _tmp $cfg
    chezmoi --config $_bare_cfg --source $_src execute-template --init $argv < $_cfg_tmpl > $cfg; or return 1
    chezmoi --config $cfg execute-template '{{ get . "cc_host" | toJson }}'
end

function _render --description 'render source template $argv[1] with data JSON $argv[2]'
    chezmoi --config $_bare_cfg --source $_src execute-template --override-data $argv[2] < $argv[1]
end

@echo "config template: cc_host"

@test "an answer is stored" \
    (_answer --promptBool "$_prompt=true") = true

@test "a stored answer is kept without prompting" \
    (_answer --override-data '{"cc_host":false}' --promptBool "$_prompt=true") = false

@test "chezmoi.test.toml answers cc_host" \
    (chezmoi --config $_test_cfg execute-template '{{ hasKey . "cc_host" }}') = true

@echo "tmux-cc.service is deployed only on a cc host"

@test "ignored when cc_host is false" \
    (_render $_ignore '{"cc_host":false}' | string match -q '.config/systemd/user/tmux-cc.service'; and echo yes; or echo no) = yes

@test "ignored when cc_host is unanswered" \
    (_render $_ignore '{}' | string match -q '.config/systemd/user/tmux-cc.service'; and echo yes; or echo no) = yes

@test "not ignored when cc_host is true" \
    (_render $_ignore '{"cc_host":true}' | string match -q '.config/systemd/user/tmux-cc.service'; and echo yes; or echo no) = no

@test "unit runs tmux by absolute path" \
    (string match -rq '^ExecStart=/\S+/tmux new-session -d -s cc' < $_unit; echo $status) = 0

@echo "enable script runs only on a cc host"

@test "script renders empty when cc_host is false (chezmoi skips it)" \
    (_render $_script '{"cc_host":false}' | string trim | string length -q; and echo content; or echo empty) = empty

@test "script enables tmux-cc.service when cc_host is true" \
    (_render $_script '{"cc_host":true}' | string match -q '*systemctl --user enable --now tmux-cc.service*'; and echo yes; or echo no) = yes

@test "script passes bash syntax check" \
    (_render $_script '{"cc_host":true}' | bash -n; echo $status) = 0

trash $_tmp

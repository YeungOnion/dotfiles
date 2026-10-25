#!/usr/bin/env fish
# ssh config: the blizzard-vjff9dr-wsl login user is a per-machine answer from chezmoi init, and
# machine-only hosts live in ~/.ssh/config.local, which chezmoi refuses to add.
# Run: fishtape tests/fish/ssh_config_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _cfg_tmpl $_repo_root/home/.chezmoi.toml.tmpl
set -g _ssh_tmpl $_repo_root/home/private_dot_ssh/private_config.tmpl
set -g _test_cfg $_repo_root/chezmoi.test.toml

set -g _tmp
# a bare config, so this machine's own answers never leak into these renders
set -g _bare_cfg (mktemp --suffix .toml)
set -ga _tmp $_bare_cfg
printf '[data]\n  java_home = ""\n' > $_bare_cfg

function _user --description 'render the config template (argv: chezmoi flags), read cc_host_user back as chezmoi would'
    set -l cfg (mktemp --suffix .toml)
    set -ga _tmp $cfg
    chezmoi --config $_bare_cfg --source $_repo_root/home execute-template --init $argv < $_cfg_tmpl > $cfg; or return 1
    chezmoi --config $cfg execute-template '{{ get . "cc_host_user" | toJson }}'
end

@echo "config template: cc_host_user"

@test "an answer is stored" \
    (_user --promptString 'Linux user on blizzard-vjff9dr-wsl (blank: no ssh entry)=alice') = '"alice"'

@test "a stored answer is kept without prompting" \
    (_user --override-data '{"cc_host_user":"alice"}') = '"alice"'

# the cc host is the ssh target, not a client: it gets no entry for itself
@test "the cc host stores a blank user, even over an old answer" \
    (_user --override-data '{"cc_host":true,"cc_host_user":"alice"}') = '""'

@test "a client keeps its answer" \
    (_user --override-data '{"cc_host":false,"cc_host_user":"alice"}') = '"alice"'

@test "chezmoi.test.toml answers cc_host_user" \
    (chezmoi --config $_test_cfg execute-template '{{ hasKey . "cc_host_user" }}') = true

@echo "ssh config template"

function _ssh --description 'render the ssh config for cc_host_user $argv[1] into a temp file, print its path'
    set -l f (mktemp)
    set -ga _tmp $f
    chezmoi --config $_bare_cfg execute-template --override-data (jq -nc --arg u $argv[1] '{cc_host_user: $u}') < $_ssh_tmpl > $f; or return 1
    echo $f
end

set -l f (_ssh alice)
@test "ssh logs in to blizzard-vjff9dr-wsl as the answer" \
    (ssh -G -F $f blizzard-vjff9dr-wsl </dev/null | string match -r '^user .*') = 'user alice'

# Include inside a Host block applies only to that host: it must precede every Host line
@test "config.local is included before any Host block" \
    (string match -rv '^\s*(#.*)?$' < $f)[1] = 'Include config.local'

set -l f (_ssh '')
@test "a blank answer renders no blizzard-vjff9dr-wsl entry" \
    (string match -q '*blizzard-vjff9dr-wsl*' < $f; and echo yes; or echo no) = no

@echo "chezmoi add refuses ~/.ssh contents other than config"

set -g _dest (mktemp -d)
set -ga _tmp $_dest
mkdir -m 700 $_dest/.ssh
touch $_dest/.ssh/config.local $_dest/.ssh/id_test

function _ignored --description 'yes if chezmoi add would ignore destination file $argv[1]'
    chezmoi --no-pager --config $_test_cfg --source $_repo_root/home --destination $_dest \
        add --dry-run --verbose $_dest/$argv[1] </dev/null 2>&1 | string match -q "*ignoring $argv[1]*"
    and echo yes; or echo no
end

@test "config.local is ignored" (_ignored .ssh/config.local) = yes
@test "a key is ignored" (_ignored .ssh/id_test) = yes
touch $_dest/.ssh/config
@test "config itself is not ignored" (_ignored .ssh/config) = no


@echo "the cc abbr attaches to the same host"

set -g _host (string match -rg '^Host (\S+)' < $_ssh_tmpl)
# new-session -A attaches to cc, or creates it when the server or session is gone
set -g _cc_abbr (fish --no-config -c "source $_repo_root/home/private_dot_config/private_fish/aliases.fish; abbr --show" | string match '* -- cc *')
@test "cc abbr targets the ssh config's Host" \
    (string match -q "*ssh -t $_host *tmux new-session -A -s cc*" -- $_cc_abbr; and echo yes; or echo no) = yes

# single-quoted in the abbr, so the client's target is read on the client when cc runs
@test "cc abbr forwards the client's target, unexpanded" \
    (string match -q '*"terminal_theme $(string escape -- "$(terminal_theme)"); tmux*' -- $_cc_abbr; and echo yes; or echo no) = yes

# the host's fish parses the forwarded string: a hostile value must stay one literal argument
@test "forwarded terminal_theme cannot inject commands on the host" \
    (function terminal_theme; echo 'light; echo PWNED'; end
     fish --no-config -c "function terminal_theme; echo \$argv; end; terminal_theme $(string escape -- "$(terminal_theme)")"
     functions -e terminal_theme) = 'light; echo PWNED'

trash $_tmp

# ── the remote command, expanded the way the client's fish will ───────────────

source (status dirname)/helpers/terminal_theme_env.fish

# the double-quoted remote command from the abbr, run through echo on the client side
set -g _remote (string match -rg '"(terminal_theme .*)"\'?$' -- $_cc_abbr)
printf 'echo "%s"\n' $_remote >$_root/expand.fish

@test "the abbr has a remote command" \
    (count $_remote) = 1

_fresh
_tt 'terminal_theme light'
@test "a client targeting light sends terminal_theme light" \
    (_tt "source $_root/expand.fish") = 'terminal_theme light; tmux new-session -A -s cc'

_put (_target_file) 'blue\n'
@test "a client with a bad target sends an empty argument, which only prints" \
    (_tt "source $_root/expand.fish") = "terminal_theme ''; tmux new-session -A -s cc"

_teardown

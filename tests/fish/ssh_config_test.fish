#!/usr/bin/env fish
# ssh config: the desktop-wsl login user is a per-machine answer from chezmoi init, and
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

function _user --description 'render the config template (argv: chezmoi flags), read desktop_wsl_user back as chezmoi would'
    set -l cfg (mktemp --suffix .toml)
    set -ga _tmp $cfg
    chezmoi --config $_bare_cfg --source $_repo_root/home execute-template --init $argv < $_cfg_tmpl > $cfg; or return 1
    chezmoi --config $cfg execute-template '{{ get . "desktop_wsl_user" | toJson }}'
end

@echo "config template: desktop_wsl_user"

@test "an answer is stored" \
    (_user --promptString 'Linux user on desktop-wsl (blank: no ssh entry)=alice') = '"alice"'

@test "a stored answer is kept without prompting" \
    (_user --override-data '{"desktop_wsl_user":"alice"}') = '"alice"'

@test "chezmoi.test.toml answers desktop_wsl_user" \
    (chezmoi --config $_test_cfg execute-template '{{ hasKey . "desktop_wsl_user" }}') = true

@echo "ssh config template"

function _ssh --description 'render the ssh config for desktop_wsl_user $argv[1] into a temp file, print its path'
    set -l f (mktemp)
    set -ga _tmp $f
    chezmoi --config $_bare_cfg execute-template --override-data (jq -nc --arg u $argv[1] '{desktop_wsl_user: $u}') < $_ssh_tmpl > $f; or return 1
    echo $f
end

set -l f (_ssh alice)
@test "ssh logs in to desktop-wsl as the answer" \
    (ssh -G -F $f desktop-wsl </dev/null | string match -r '^user .*') = 'user alice'

# Include inside a Host block applies only to that host: it must precede every Host line
@test "config.local is included before any Host block" \
    (string match -rv '^\s*(#.*)?$' < $f)[1] = 'Include config.local'

set -l f (_ssh '')
@test "a blank answer renders no desktop-wsl entry" \
    (string match -q '*desktop-wsl*' < $f; and echo yes; or echo no) = no

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

trash $_tmp

#!/usr/bin/env fish
# tmux: the status line shows the hostname (#H) plus a WSL marker. The marker comes from
# the kernel release, because the systemd-started server may lack WSL_DISTRO_NAME.
# Each case runs a private tmux server (-L) with a stub `uname` first on its PATH.
# Run: fishtape tests/fish/tmux_host_marker_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _conf_d $_repo_root/home/private_dot_config/tmux/conf.d
set -g _tmp

function _marker --description 'value of @host_marker after sourcing host.conf with uname -r printing $argv[1]'
    set -l stub (mktemp -d)
    set -ga _tmp $stub
    printf '#!/bin/sh\necho %s\n' $argv[1] > $stub/uname
    chmod +x $stub/uname
    set -l sock marker-test-$fish_pid
    env -u WSL_DISTRO_NAME PATH=(string join : $stub $PATH) tmux -L $sock -f /dev/null new-session -d
    tmux -L $sock source-file $_conf_d/host.conf
    tmux -L $sock show -gv @host_marker
    tmux -L $sock kill-server
end

@echo "host.conf: WSL marker from the kernel release"

@test "a WSL kernel sets the marker" \
    (_marker 6.18.54.1-microsoft-standard-WSL2) = ' wsl'

@test "a native kernel leaves it empty" \
    (_marker 6.8.0-45-generic | string collect) = ''

@echo "the status line uses it"

@test "status-right puts the marker after #H" \
    (string match -q '*#H#{@host_marker}*' < $_conf_d/theme.conf; and echo yes; or echo no) = yes

@test "tmux.conf sources host.conf before theme.conf" \
    (string match -r 'conf\.d/(host|theme)\.conf' < $_repo_root/home/private_dot_config/tmux/tmux.conf | string match -rv '^conf' | string join ,) = host,theme

trash $_tmp

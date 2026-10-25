# Shared fixture for terminal theme tests: a temp XDG config/state root and a private
# tmux server, so tests never touch the live terminal_theme uvar, target file or tmux server.
# Source it from a test file. tmux sockets are limited to ~108 bytes, so the root comes
# from mktemp -d (/tmp), not a deep scratch directory.

set -g _repo_root (path resolve (status dirname)/../../..)
set -g _fish_src $_repo_root/home/private_dot_config/private_fish
set -g _tmux_src $_repo_root/home/private_dot_config/tmux

set -g _root (mktemp -d)
mkdir -p $_root/cfg/fish/conf.d $_root/cfg/tmux $_root/state
# only the theme snippet from conf.d: the others (nudge, installers, plugins) are noise here
ln -s $_fish_src/functions $_root/cfg/fish/functions
ln -s $_fish_src/conf.d/terminal_theme.fish $_root/cfg/fish/conf.d/terminal_theme.fish
ln -s $_tmux_src/conf.d $_root/cfg/tmux/conf.d

# Plain fish, not --no-config: universals must load. The temp XDG_CONFIG_HOME has no
# config.fish, so PATH stays as the test's.
function _tt --description 'run fish code in the temp theme environment'
    env -u TMUX XDG_CONFIG_HOME=$_root/cfg XDG_STATE_HOME=$_root/state TMUX_TMPDIR=$_root \
        fish -c "$argv"
end

function _tmux --description 'tmux against the private server'
    env -u TMUX TMUX_TMPDIR=$_root tmux $argv
end

function _tmux_up
    _tmux -f /dev/null new-session -d -s t
end

function _tmux_down
    _tmux kill-server 2>/dev/null
    return 0
end

function _palette --description 'the private server @thm_theme_name'
    _tmux show -gv @thm_theme_name 2>/dev/null
end

function _uvar --description 'terminal_theme as a fresh shell in the temp environment sees it'
    _tt 'echo $terminal_theme'
end

function _target_file
    echo $_root/state/terminal-theme/target
end

function _system_file
    echo $_root/state/terminal-theme/system
end

function _put --description 'write raw content $argv[2] to state file $argv[1], creating the dir'
    mkdir -p $_root/state/terminal-theme
    printf '%b' $argv[2] >$argv[1]
end

function _fresh --description 'no tmux server, no state, no universals'
    _tmux_down
    chmod -R u+rwx $_root/state 2>/dev/null
    trash $_root/state $_root/cfg/fish/fish_variables 2>/dev/null
    mkdir -p $_root/state
end

function _teardown
    _tmux_down
    chmod -R u+rwx $_root 2>/dev/null
    # trash follows symlinks: unlink them first so the source tree is never trashed
    unlink $_root/cfg/fish/functions
    unlink $_root/cfg/fish/conf.d/terminal_theme.fish
    unlink $_root/cfg/tmux/conf.d
    trash $_root
end

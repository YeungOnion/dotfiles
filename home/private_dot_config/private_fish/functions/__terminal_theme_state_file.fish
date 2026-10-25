# Pure: path of a terminal theme state file. target is the theme the user chose
# (terminal_theme), system is what the Windows poller last saw. Both live under
# $XDG_STATE_HOME (default ~/.local/state); chezmoi seeds target with dark.
function __terminal_theme_state_file -a name
    contains -- "$name" target system; or return 2
    set -l root $XDG_STATE_HOME
    test -n "$root"; or set root ~/.local/state
    echo $root/terminal-theme/$name
end

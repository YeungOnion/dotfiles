# Impure: source the tmux palette for light or dark. The file is picked by a switch,
# never built from the value; anything else returns 1. No server is not an error: the
# next server start runs theme.conf, which applies the target. Reachability is a
# show-options query: has-session fails while theme.conf loads at server start (no
# session yet), and a socket file outlives kill-server; show-options works in the first
# case, fails in the second, and never starts a server.
function __terminal_theme_tmux -a theme
    switch "$theme"
        case light
            set -f palette palette_light.conf
        case dark
            set -f palette palette_dark.conf
        case '*'
            echo "terminal_theme: no tmux palette for '$theme'" >&2
            return 1
    end

    command -q tmux; or return 0
    command tmux show-options -gqv status >/dev/null 2>&1; or return 0

    set -l root $XDG_CONFIG_HOME
    test -n "$root"; or set root ~/.config
    command tmux source-file $root/tmux/conf.d/$palette
end

# Impure: make light or dark the target and apply it once - target file, tmux
# palette, terminal_theme universal. Per-shell effects (BAT_THEME, LS_COLORS) follow
# from the universal in each shell's __terminal_theme_apply handler. Nothing is
# applied when the target can't be written; a failed tmux source still publishes.
function __terminal_theme_assign -a theme
    __terminal_theme_write (__terminal_theme_state_file target) $theme; or return

    set -l result 0
    __terminal_theme_tmux $theme; or set result $status
    __terminal_theme_publish $theme; or set result $status
    return $result
end

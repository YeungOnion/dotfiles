function terminal_theme --description 'print or set the target light/dark theme: terminal_theme [light | dark | toggle | apply | system]'
    # Every change ends in an assignment (light or dark): write the target file,
    # source the tmux palette, publish the terminal_theme universal. Scripts call it
    # as `fish -c 'terminal_theme dark'`; tmux's theme.conf runs `terminal_theme apply`,
    # so changes print nothing (run-shell would show it). An invalid target is reset to
    # dark by toggle/apply; an invalid or missing system file changes nothing.
    if test (count $argv) -gt 1
        echo "usage: terminal_theme [light | dark | toggle | apply | system]" >&2
        return 2
    end

    switch "$argv[1]"
        case ''
            __terminal_theme_read (__terminal_theme_state_file target)
        case light
            __terminal_theme_assign light
        case dark
            __terminal_theme_assign dark
        case toggle
            switch (__terminal_theme_read (__terminal_theme_state_file target))
                case light
                    terminal_theme dark
                case dark
                    terminal_theme light
                case '*'
                    __terminal_theme_reset
            end
        case apply
            switch (__terminal_theme_read (__terminal_theme_state_file target))
                case light
                    terminal_theme light
                case dark
                    terminal_theme dark
                case '*'
                    __terminal_theme_reset
            end
        case system
            # no system state (no poller, not WSL, or bad data): no report, no change
            switch (__terminal_theme_read (__terminal_theme_state_file system))
                case light
                    terminal_theme light
                case dark
                    terminal_theme dark
                case '*'
                    return 0
            end
        case '*'
            echo "usage: terminal_theme [light | dark | toggle | apply | system]" >&2
            return 2
    end
end

function __terminal_theme_reset --description 'the target was unreadable or invalid: assign dark'
    echo "terminal_theme: target state was invalid, reset to dark" >&2
    __terminal_theme_assign dark
end

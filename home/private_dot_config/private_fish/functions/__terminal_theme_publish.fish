# Impure: the only code that writes the terminal_theme universal (change the theme
# with terminal_theme, never set -U). Each shell's __terminal_theme_apply handler
# (conf.d/terminal_theme.fish) reacts. Writes only on a change, so other shells'
# handlers fire only for a real change; anything but light or dark returns 1.
# `if`, not `test …; or set …`: set passes the failed test's status through.
function __terminal_theme_publish -a theme
    switch "$theme"
        case light
            if test "$terminal_theme" != light
                set -U terminal_theme light
            end
        case dark
            if test "$terminal_theme" != dark
                set -U terminal_theme dark
            end
        case '*'
            return 1
    end
end

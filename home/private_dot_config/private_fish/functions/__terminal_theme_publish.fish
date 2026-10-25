# Impure: the only code that writes the terminal_theme universal (change the theme
# with terminal_theme, never set -U). Each shell's __terminal_theme_apply handler
# (conf.d/terminal_theme.fish) reacts. Writes only on a change, so other shells'
# handlers fire only for a real change; anything but light or dark returns 1.
function __terminal_theme_publish -a theme
    switch "$theme"
        case light
            test "$terminal_theme" = light; or set -U terminal_theme light
        case dark
            test "$terminal_theme" = dark; or set -U terminal_theme dark
        case '*'
            return 1
    end
end

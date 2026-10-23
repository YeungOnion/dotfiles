function terminal_theme --description 'print or set the light/dark terminal_theme uvar: terminal_theme [light | dark | toggle]'
    # Scripts call it as `fish -c 'terminal_theme dark'`. Effects (BAT_THEME,
    # LS_COLORS) come from __terminal_theme_apply in conf.d/terminal_theme.fish.
    if test (count $argv) -gt 1
        echo "usage: terminal_theme [light | dark | toggle]" >&2
        return 2
    end
    __terminal_theme_set terminal_theme $argv
end

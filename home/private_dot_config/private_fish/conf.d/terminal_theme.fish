# Pure: parse raw reg.exe output → light | dark | unknown
function __terminal_theme_parse
    set -l matches (string match -r '0x(\w+)' -- $argv)
    switch $matches[2]
        case 1
            echo light
        case 0
            echo dark
        case '*'
            echo unknown
    end
end

# Impure: query Windows registry, print result to stdout
function __terminal_theme_query
    __terminal_theme_parse (reg.exe query \
        "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" \
        /v AppsUseLightTheme 2>/dev/null)
end

# Pure: bat theme name for light|dark, respects BAT_THEME_LIGHT/BAT_THEME_DARK overrides
function __terminal_theme_bat_name -a theme
    switch $theme
        case light
            set -q BAT_THEME_LIGHT && echo $BAT_THEME_LIGHT || echo GitHub
        case dark
            set -q BAT_THEME_DARK && echo $BAT_THEME_DARK || echo Dracula
    end
end

# Pure: vivid theme name for light|dark, respects VIVID_THEME_LIGHT/VIVID_THEME_DARK overrides
function __terminal_theme_vivid_name -a theme
    switch $theme
        case light
            set -q VIVID_THEME_LIGHT && echo $VIVID_THEME_LIGHT || echo one-light
        case dark
            set -q VIVID_THEME_DARK && echo $VIVID_THEME_DARK || echo dracula
    end
end

# Effect: apply BAT_THEME and LS_COLORS whenever terminal_theme changes
function __terminal_theme_apply --on-variable terminal_theme
    switch $terminal_theme
        case light dark
            set -gx BAT_THEME (__terminal_theme_bat_name $terminal_theme)
            set -gx LS_COLORS (vivid generate (__terminal_theme_vivid_name $terminal_theme))
    end
end

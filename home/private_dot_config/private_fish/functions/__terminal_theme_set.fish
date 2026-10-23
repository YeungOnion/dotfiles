# Impure: read or change the $var_name uvar. action (argv[2]) is light, dark,
# toggle, or empty (print the current value, "unknown" when neither light nor
# dark). Writes only when the value changes, so other shells' --on-variable
# handlers fire only on a real change. Returns 2 on a bad action. The variable
# name is a parameter so tests never touch the real terminal_theme uvar; the
# real caller is terminal_theme (functions/terminal_theme.fish).
function __terminal_theme_set -a var_name action
    set -l current unknown
    contains -- "$$var_name" light dark; and set current $$var_name

    switch "$action"
        case ''
            echo $current
            return 0
        case light dark
            set -f new $action
        case toggle
            # unset/unknown toggles to light: terminals start out dark
            test "$current" = light; and set -f new dark; or set -f new light
        case '*'
            echo "usage: terminal_theme [light | dark | toggle]" >&2
            return 2
    end

    test "$current" = "$new"; or set -U $var_name $new
    echo $new
end

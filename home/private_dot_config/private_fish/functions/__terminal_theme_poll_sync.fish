# Impure: run $query_cmd (argv[2..]), write result into the $var_name uvar
# iff the value changed and is not "unknown". Both the target variable name
# and the query command are parameters (not hardcoded) so this is testable
# without reg.exe/WSL and without mutating the real terminal_theme uvar.
# The real caller (scripts/executable_terminal-theme-poll.fish) passes
# terminal_theme and __terminal_theme_query (conf.d/terminal_theme.fish).
function __terminal_theme_poll_sync -a var_name
    set -l query_cmd $argv[2..]
    set -l new_theme ($query_cmd)

    if test "$new_theme" = unknown
        return 1
    end

    if test "$$var_name" = "$new_theme"
        return 0
    end

    set -U $var_name $new_theme
end

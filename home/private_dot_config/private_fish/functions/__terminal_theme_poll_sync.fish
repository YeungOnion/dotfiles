# Impure: run $query_cmd (argv[2..]) and record its result in the system state
# file $file iff it is light or dark and differs from what the file holds; anything
# else ("unknown", or no output from a query that failed to run) returns 1. This is
# observation only: the target and the terminal_theme universal change only through
# terminal_theme (`terminal_theme system` copies this state on request). Both the file
# and the query are parameters so this is testable without reg.exe/WSL.
# The real caller (scripts/executable_terminal-theme-poll.fish) passes the system
# state file and __terminal_theme_query (conf.d/terminal_theme.fish).
function __terminal_theme_poll_sync -a file
    set -l query_cmd $argv[2..]
    set -l new_theme ($query_cmd)

    if not contains -- "$new_theme" light dark
        return 1
    end

    if test "$(__terminal_theme_read $file)" = "$new_theme"
        return 0
    end

    __terminal_theme_write $file $new_theme
end

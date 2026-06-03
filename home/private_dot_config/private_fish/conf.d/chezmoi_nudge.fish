set -g __chezmoi_src (chezmoi source-path 2>/dev/null)

function __chezmoi_nudge --on-event fish_postexec
    set -l prev_status $status
    set -l cmd $argv[1]

    # Branch 1: install nudge — lexical match only, no subprocesses
    if string match -rq '\b(install|binstall)\b' -- $cmd
        and string match -rq '^(brew|cargo)\s|^uv\s+tool\s' -- $cmd
        if test -n "$__chezmoi_src"
            echo "chezmoi?: hx $__chezmoi_src/.chezmoiscripts/" >&2
        end
    end

    # Branch 2: apply reminder — fires only when editor opened a chezmoiscript
    if string match -rq '^\s*(hx|vim|nvim|nano)\s' -- $cmd
        and string match -rq '\.chezmoiscripts/' -- $cmd
        if chezmoi status 2>/dev/null | string match -rq '^\s*R.*chezmoiscripts'
            echo "chezmoi: script changes pending → chezmoi apply" >&2
        end
    end

    return $prev_status
end

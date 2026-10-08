function __chezmoi_nudge --on-event fish_postexec
    set -l prev_status $status
    set -l cmd $argv[1]

    # Resolved lazily so chezmoi need not be in PATH at conf.d load time
    if not set -q __chezmoi_src
        command -q chezmoi && set -g __chezmoi_src (chezmoi source-path)
    end

    # Branches 1/3/4: hand-made changes that belong in chezmoi data → usage of the task that records them
    if test -n "$__chezmoi_src"
        set -l usage (__chezmoi_nudge_task $cmd)
        and echo "chezmoi?: mise -C "(path dirname $__chezmoi_src)" run $usage" >&2
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

function __chezmoi_nudge_task --description 'Usage of the mise task that records a hand-made change in chezmoi data'
    # Lexical only, no subprocesses: recognise the kind of command, not its arguments.
    # Returns 1 (prints nothing) when no task applies.
    set -l cmd (string replace -r '^\s*(command\s+)?' '' -- $argv[1])
    if string match -rq '^brew\s+(install|uninstall|remove)\b|^cargo\s+(install|binstall|uninstall)\b|^uv\s+tool\s+(install|uninstall)\b' -- $cmd
        echo 'pkg add|remove <manager> <name>'
    else if string match -rq '^fisher\s+(install|remove|uninstall)\b' -- $cmd
        echo 'fish-plugin add|remove <owner/repo>'
    else if string match -rq '^set\s+(-(?![a-zA-Z]*[qnSL])[a-zA-Z]*U[a-zA-Z]*|--universal)\s' -- $cmd
        # set -U / -Ux / -eU / --universal: a universal change. Not the read-only
        # -q (query), -n (names), -S (show), -L (long listing) forms.
        echo 'fish-var set|unset <name> [value]'
    else
        return 1
    end
end

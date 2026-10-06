function scratch --description 'open tmuxinator scratch project in $HOME/sandbox/(today)/<name>'
    # fish has no errexit/pipefail: every fallible command returns on failure
    if test (count $argv) -gt 1
        echo "usage: scratch [name | YYMMDD[/path] | existing/path]" >&2
        return 1
    end

    if test (count $argv) -eq 0
        tmuxinator start scratch
        return
    end

    set -f today (date +%y%m%d); or return
    set -f arg $argv[1]

    # date-prefixed args address the sandbox root; everything else is under today
    if string match -qr '^\d{6}' -- $arg
        set -f rel $arg
    else
        set -f rel $today/$arg
    end

    # date-prefixed or nested args must name an existing dir; plain names are created
    if string match -qr '^\d{6}|/' -- $arg; and not test -d $HOME/sandbox/$rel
        echo "scratch: $HOME/sandbox/$rel does not exist" >&2
        return 1
    end

    tmuxinator start scratch $rel
end

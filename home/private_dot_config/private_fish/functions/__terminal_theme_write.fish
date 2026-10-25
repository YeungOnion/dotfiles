# Impure: atomically write light or dark to $file (temp file + mv), creating its
# directory with mode 700. Any other value returns 2 and writes nothing. A directory
# at $file returns 1: mv would otherwise move the temp file into it and succeed.
function __terminal_theme_write -a file theme
    contains -- "$theme" light dark; or return 2
    if test -d "$file"
        echo "terminal_theme: $file is a directory, not writing" >&2
        return 1
    end
    mkdir -p -m 700 (path dirname -- $file); or return 1

    set -l tmp $file.tmp.$fish_pid
    printf '%s\n' $theme >$tmp; or return 1
    chmod 644 $tmp
    if not mv -f $tmp $file
        command rm -f $tmp
        return 1
    end
end

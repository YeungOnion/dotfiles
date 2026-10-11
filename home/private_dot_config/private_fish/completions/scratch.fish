# scratch [name | YYMMDD[/path] | existing/path]
# Mirrors scratch's argument rules, independent of the current directory:
# a date-prefixed token completes paths under ~/sandbox; anything else completes
# existing subdirectories of today's dir (a plain new name is created by scratch).

function __scratch_complete
    set -l token (commandline -ct)
    set -l sandbox $HOME/sandbox
    set -l today (date +%y%m%d)

    if test -z "$token"; or string match -qr '^\d' -- $token
        # date dirs and their subdirs, relative to ~/sandbox
        for dir in $sandbox/$token*/
            printf '%s\tdate\n' (string replace -- "$sandbox/" '' $dir)
        end
    end
    if not string match -qr '^\d' -- $token
        # subdirs of today's dir, relative to it
        for dir in $sandbox/$today/$token*/
            printf '%s\ttoday\n' (string replace -- "$sandbox/$today/" '' $dir)
        end
    end
end

complete -c scratch --no-files --arguments '(__scratch_complete)'

# Impure (reads $file): print light or dark when the file holds exactly that word
# (one trailing newline allowed). Anything else - missing, unreadable, a directory,
# empty, padded, two lines, any other word - prints nothing and returns 1, so callers
# switch on the result and never use raw file content.
function __terminal_theme_read -a file
    test -f "$file" -a -r "$file"; or return 1
    # string collect keeps a second line in the same value, so it fails the check
    set -l value (string collect <$file 2>/dev/null)
    contains -- "$value" light dark; or return 1
    echo $value
end

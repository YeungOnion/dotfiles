#!/usr/bin/env fish
# Script 04 must set universal variables verbatim, whatever characters values contain.
# Runs the rendered script against a temp XDG_CONFIG_HOME: real universals are never touched.
# Run: fishtape tests/fish/fish_universal_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _script $_repo_root/home/.chezmoiscripts/run_onchange_04-fish-universal.sh.tmpl

set -g _xdg (mktemp -d)
set -g _data (mktemp --suffix .json)
# values a user might pass to `mise run fish-var set`
jq -n '{fish_universal: {
    GREETING: "it'"'"'s $(echo pwned); echo pwned",
    OPTS: "--height 40% --layout=reverse",
    SLASHES: "a\\\\b \\\\n"
}}' > $_data

set -l rendered (mktemp --suffix .sh)
chezmoi execute-template --override-data-file $_data < $_script > $rendered
set -l run_status (env XDG_CONFIG_HOME=$_xdg bash $rendered >/dev/null 2>&1; echo $status)

function _get --description 'read a universal from the temp fish config, one element per line'
    env XDG_CONFIG_HOME=$_xdg fish -c "printf '%s\n' \$$argv[1]"
end

@echo "script 04 sets values verbatim"

@test "rendered script runs" \
    $run_status = 0

@test "quote, \$(), ; are kept literally" \
    "$(_get GREETING)" = "it's \$(echo pwned); echo pwned"

@test "value with spaces stays one element" \
    (count (_get OPTS)) = 1

@test "value with spaces is verbatim" \
    "$(_get OPTS)" = "--height 40% --layout=reverse"

@test "backslashes are kept literally" \
    "$(_get SLASHES)" = "$(jq -r .fish_universal.SLASHES $_data)"

trash $_xdg $_data $rendered

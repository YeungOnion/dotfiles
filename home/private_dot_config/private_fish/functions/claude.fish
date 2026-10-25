function claude --description 'claude with its theme from terminal_theme (per launch, like BAT_THEME)'
    # Claude Code has no theme env var but honors `theme` from --settings
    # (tests/fish/deps/claude_settings_theme_test.fish). The name is checked, not
    # escaped, before it goes into the JSON. /theme inside a session is not tracked.
    set -l name (__terminal_theme_claude_name "$terminal_theme")
    if test -z "$name"
        command claude $argv
        return
    end
    if not string match -rq '^[a-z0-9:-]+$' -- $name
        echo "claude: theme name '$name' is not a plain name, not passing it" >&2
        command claude $argv
        return
    end
    command claude --settings "{\"theme\":\"$name\"}" $argv
end

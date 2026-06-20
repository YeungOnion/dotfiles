# Disable default file completions ONLY when we want to force a subcommand
# But note: we do NOT use -f globally so that "glow [TAB]" suggests files too.

# --- Global Flags ---
complete -c glow -s h -l help -d 'Help for glow'
complete -c glow -l config -r -d 'Config file path'
complete -c glow -s a -l all -d 'Show system files (TUI only)'
complete -c glow -s l -l local -d 'Show local files only'
complete -c glow -s p -l pager -d 'Display with pager'
complete -c glow -s v -l version -d 'Show version'
complete -c glow -s w -l width -x -d 'Word-wrap width'
complete -c glow -s s -l style -x -d 'Style name or JSON path'

# --- Subcommands ---
complete -c glow -f -n __fish_use_subcommand -a stash -d 'Stash a markdown'
complete -c glow -f -n __fish_use_subcommand -a config -d 'Edit the glow config file'
complete -c glow -f -n __fish_use_subcommand -a help -d 'Help about any command'
complete -c glow -f -n __fish_use_subcommand -a completion -d 'Generate autocompletion script'

# --- Stash Command Logic ---
# Allow files for stash (no -f), but add stash-specific flags
complete -c glow -n '__fish_seen_subcommand_from stash' -s m -l memo -x -d 'Memo/note for stashing'
complete -c glow -n '__fish_seen_subcommand_from stash' -s h -l help -d 'Help for stash'

# --- Help Command Logic ---
# Suggest other subcommands as arguments for 'help'
complete -c glow -f -n '__fish_seen_subcommand_from help' -a 'stash config completion'

# --- Config Command Logic ---
complete -c glow -n '__fish_seen_subcommand_from config' -s h -l help -d 'Help for config'

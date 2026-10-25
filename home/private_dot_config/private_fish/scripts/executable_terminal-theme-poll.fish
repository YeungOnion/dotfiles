#!/usr/bin/env fish
# Invoked by terminal-theme-poll.service (systemd --user timer); not sourced
# by interactive shells and not in a fish autoload directory. Polls the
# Windows registry via __terminal_theme_query (conf.d/terminal_theme.fish,
# auto-sourced for this non-interactive invocation too) and records it in the
# terminal-theme system state file on change. It never changes the target or
# the terminal_theme universal: `terminal_theme system` copies it on request.
__terminal_theme_poll_sync (__terminal_theme_state_file system) __terminal_theme_query

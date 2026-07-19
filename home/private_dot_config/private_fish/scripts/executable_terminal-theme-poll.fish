#!/usr/bin/env fish
# Invoked by terminal-theme-poll.service (systemd --user timer); not sourced
# by interactive shells and not in a fish autoload directory. Polls the
# Windows registry via __terminal_theme_query (conf.d/terminal_theme.fish,
# auto-sourced for this non-interactive invocation too) and pushes into the
# terminal_theme uvar on change. __terminal_theme_apply (--on-variable
# terminal_theme, same file) reacts automatically — no interactive-path
# code is involved in this update at all.
__terminal_theme_poll_sync terminal_theme __terminal_theme_query

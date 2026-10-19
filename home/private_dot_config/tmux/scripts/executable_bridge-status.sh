#!/usr/bin/env bash
# Status-bar dot for the ai-job-search cowork bridge (loopback, see that
# repo's `mise run bridge`). tmux passes the session name; every other session
# gets no output. /healthz needs no token and answers in ~50 ms.
#
#   ● bridge       up
#   ● bridge ✉2    up, 2 Cowork messages not yet read here (/leads inbox)
#   ○ bridge       down
#
# Colors come from the theme palette at run time, since #{...} formats in
# #() output are not reliably expanded.

[[ "${1:-}" == "ai-job-search" ]] || exit 0

color() { tmux show -gv "$1" 2>/dev/null; }

body=$(curl -s --max-time 1 "http://127.0.0.1:${BRIDGE_PORT:-8765}/healthz") || body=""
if [[ -z "$body" ]]; then
  printf '#[fg=%s]○ bridge ' "$(color @thm_overlay)"
  exit 0
fi

unread=$(jq -r '.unread["claude-code"] // 0' <<<"$body" 2>/dev/null || echo 0)
if [[ "$unread" =~ ^[1-9][0-9]*$ ]]; then
  printf '#[fg=%s]● bridge #[fg=%s,bold]✉%s#[nobold] ' "$(color @thm_green)" "$(color @thm_pink)" "$unread"
else
  printf '#[fg=%s]● bridge ' "$(color @thm_green)"
fi

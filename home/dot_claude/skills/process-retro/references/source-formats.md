# Source formats

Inspect every source before relying on this file. Entries marked **verified** were measured; the rest are expectations to check.

## Claude Code transcripts (verified, version 2.1.304)

- Location: `~/.claude/projects/<cwd with / as ->/<session-id>.jsonl`; subagents in `<session-id>/subagents/agent-*.jsonl`; large tool output in `<session-id>/tool-results/`.
- One JSON object per line. `type` counts in a 6-day session: `assistant`, `user`, `system`, `attachment`, `api-request`, `queue-operation` and many bookkeeping types.
- **Human prompts:** `type=="user"` and `origin.kind=="human"`. Tool results are also `type=="user"`, so filter on `origin`. `message.content` is a string or an array of blocks; join the `text` blocks.
- Useful fields: `timestamp`, `promptSource`, `sessionId`, `cwd`, `turnPosition`.
- **Agent time:** `type=="system"` with `subtype=="turn_duration"` and `durationMs`. `subtype=="away_summary"` carries the agent's own one-line state recap, which is a cheap way to list design pivots.
- The CLI's `agent-name` and `ai-title` records can label sessions.
- `onecli`-style CLIs may print access tokens into tool results: redact.

## claude.ai chat history

Use whatever past-chat search or export tool the session has. State which one you used and what it can't return (for example, no timestamps or no attachments).

## Other LLM exports (unverified)

- ChatGPT export: expect `conversations.json` with a `mapping` of message nodes forming a tree; walk from `current_node` to the root to get the live branch.
- Gemini and others: formats vary (Takeout HTML or JSON). Look at one file with `jq` or `duckdb` before writing a normalization.

## Docs with back-and-forth

Comment threads on Claude Docs or artifacts, PR and issue threads, and markdown notes. Use the doc or artifact tools to read them, and keep thread parentage so replies stay attached to what they answer.

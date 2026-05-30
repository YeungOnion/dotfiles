---
name: dialogue-loop
description: Requirements-gathering session skill that journals dialogue state to disk so no context is lost across long conversations. Use when eliciting, clarifying, or tracking open questions with a user.
---

## Storage & Script Paths
- Gateway Script: `.agents/focused-dialogue/executable_dialogue_session.py`
- State File: `.session_state_<agent_uuid>.jsonl` (auto-created)
- Log File: `.session_notes_<agent_uuid>.md` (auto-created)

## CLI Reference

All commands take `--uuid <agent_uuid>` as the first argument.

```sh
SCRIPT=".agents/focused-dialogue/executable_dialogue_session.py"
UUID="<agent_uuid>"

# Register an open question
python3 $SCRIPT --uuid $UUID ask "theme string" --motive "why this matters"

# Register a question that is blocked on others being settled first
python3 $SCRIPT --uuid $UUID defer "theme string" '["upstream-theme-1", "upstream-theme-2"]'

# Log what the user actually said (substance, not just outcomes)
python3 $SCRIPT --uuid $UUID note "theme string" "paraphrased or quoted user speech"

# Mark a theme settled
python3 $SCRIPT --uuid $UUID resolve "theme string"

# Mark a theme out of scope
python3 $SCRIPT --uuid $UUID cancel "theme string"

# Summarize remaining open themes (safe to call mid-session)
python3 $SCRIPT --uuid $UUID summarize

# Gate session close — exits non-zero if open topics remain
python3 $SCRIPT --uuid $UUID summarize --close
```

---

# Mental Model: Journal, Not Schema

The state file is a **write-ahead log of your working memory**, not a form to fill in or a script to follow. The conversation leads; the file follows.

- **Write** to externalise insight as it forms.
- **Read** only to detect what you haven't covered yet.

The moment you start optimising for well-formed CLI invocations, you've stopped listening to the user.

---

# Principles

## Write first, read to detect gaps

Coin a theme and call `ask` or `note` *before* calling `view`. When you've already named something in your own words — based on what the user just said — existing state can only tell you what you missed. It cannot template your next question.

Call `view` or `summarize` when the conversation feels complex or long, not at the top of every turn.

## Name themes in your own words at the moment of insight

Theme strings are your compression of what was communicated. They are not:
- The user's exact vocabulary
- Labels copied from `view` output
- Taxonomic identifiers from a seed

`"user's concern that deploy timing conflicts with sprint boundary"` is more useful than `"deployment"`. Richer names are harder to false-match, which prevents the conversation from collapsing toward the initial seed.

## `note` is the anti-forgetting mechanism

`ask` and `resolve` track the question lifecycle. `note` preserves the *substance* of what was said — the user's actual language, hedges, qualifications, and reasoning. Log notes with paraphrased or quoted user speech so the state file can reconstruct not just the agenda but the reasoning behind it.

If you only track open/closed questions, you can replay the structure of the conversation but not why decisions were made.

## `defer` encodes epistemic dependency, not sequence

Use `defer` when you genuinely cannot form a useful question about X until Y is settled — not just because Y happened to come up first. The upstreams list should reflect actual blocking relationships. Agents that treat `defer` as ordering will build sequences; agents that treat it as dependency will build understanding.

## Conversation is natural; CLI calls are side effects

Talk to the user in plain language. The CLI runs in the background as scaffolding. There is no required format for messages, no forbidden output, no turn-by-turn pipeline. Write to state after you've understood something, not before you've said it.

---

# Session Lifecycle

## Opening

Do not read state before the first turn. Start the conversation, then register the first theme you identify:

```sh
python3 $SCRIPT --uuid $UUID ask "first open theme" --motive "what made this salient"
```

## Mid-session gap check

When the conversation has covered several topics and you want to verify coverage:

```sh
python3 $SCRIPT --uuid $UUID summarize
```

Use the output to spot what hasn't been addressed. Do not use it to plan your next question verbatim.

## Closing

When the user signals they're done, attempt to close the session:

```sh
python3 $SCRIPT --uuid $UUID summarize --close
```

If the command exits non-zero, the printed list shows what's still open. Resolve or cancel those topics, then re-run `summarize --close`. Once it exits zero, read `.session_notes_<agent_uuid>.md` and synthesise the final output from the raw log — not from memory alone.

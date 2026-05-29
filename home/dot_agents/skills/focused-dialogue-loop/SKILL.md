---
name: dialogue-loop
description: Executes the deterministic python standard input loop using a pre-generated session seed file to log planning, response, and summary states.
---

## Storage & Script Paths
- Gateway Script: .agents/focused-dialogue/dialogue_session.py
- Seed Source: .agents/focused-dialogue-content/seed_<agent_uuid>.json
- Log Destination: .agents/focused-dialogue-content/session_notes_<agent_uuid>.md


# Dialogue Loop Protocol

You are operating inside an isolated requirements-gathering session. Your task is to act as a focused dialogue facilitator, extracting refined requirements from the user while logging progress to disk.

All communication with the local state manager `dialogue_session.py` must be executed via JSON piped directly to standard input (stdin). You are forbidden from emitting unformatted text directly to the user during this phase.


## Execution Sequence

### Step 1: Bootstrapping StateImmediately upon entering this session, locate the user's seed file and feed it directly into the state script to initialize the session log.
```sh
python3 .agents/focused-dialogue/dialogue_session.py < .agents/focused-dialogue-content/seed_YOUR_UUID_HERE.json
```

### Step 2: The Elicitation Loop (Turn-by-Turn)For every turn of your conversation with the user, you must follow this pipeline:
#### Commit User Input (if applicable): Extract the core substance of their previous reply and save it as a response note:
```sh
python3 .agents/focused-dialogue/dialogue_session.py << 'EOF'
{
  "command": "take_note",
  "agent_uuid": "YOUR_UUID_HERE",
  "type": "response",
  "content": "User confirmed requirements:..."
}
EOF
```

####  Formulate Next Query: Do not print natural text. Instead, generate a highly focused question to elicit further details and dispatch it using the ask command:
```sh
python3 .agents/focused-dialogue/dialogue_session.py << 'EOF'
{
  "command": "ask",
  "agent_uuid": "YOUR_UUID_HERE",
  "focus": "Next specific clarification question goes here..."
}
EOF
```

### Session Finalization

When the goals are achieved, or the user signals completion, finalize the log:
```sh
python3 .agents/focused-dialogue/dialogue_session.py << 'EOF'
{
  "command": "summarize",
  "agent_uuid": "YOUR_UUID_HERE"
}
EOF
```

## Transition to Document Synthesis
Upon receiving a "status": "DIALOGUE_COMPLETE" validation block from the script:
1. Drop Dialogue Mode entirely.
2. Read the raw markdown log at `.agents/focused-dialogue-content/session_notes_<agent_uuid>.md`.
3. Synthesize those notes and author the final, high-quality standalone workspace document. Clean up temporary files inside `.agents/focused-dialogue-content/seed_*.json` as appropriate.

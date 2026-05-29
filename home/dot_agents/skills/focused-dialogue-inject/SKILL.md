---
name: dialogue-loop:inject
description: Compiles the current session context, constraints, and user preferences into a structured JSON seed file. Run this skill when preparing to transition into an isolated requirements-gathering dialogue loop.
---

# Dialogue Inject Protocol
This skill distills the complex, noisy context of the active conversation into a structured, lightweight JSON seed file. This allows you to hand off a clean "state packet" to an isolated, context-clean sub-session without carrying over conversation exhaust.
This skill is completely self-contained and runs using standard shell utilities without requiring a helper script.

## Output Specifications
Target Directory: .agents/focused-dialogue-content/
Target File: seed_<agent_uuid>.json

## Execution Protocol
When this skill is triggered, you must perform the following actions:
1. Generate a Session UUID: Create a short, unique identifier (e.g., usr- followed by 4 random alphanumeric characters like usr-98a2).
2. Synthesize the Objective: Condense all user goals, constraints, technology stacks, and requirements established in this chat into a single, high-density "objective" string.
3. Determine the Persona: Set a targeted professional persona (e.g., "Systems Architect with deep POSIX experience") to steer the sub-agent's tone.
4. Write the Seed File: Execute a shell command using a single-quoted heredoc to write the JSON to the storage directory.

## Write Template (Execute in Shell)
```sh
# Ensure the content directory exists
mkdir -p .agents/focused-dialogue-content

# Write the seed block
cat << 'EOF' > .agents/focused-dialogue-content/seed_YOUR_UUID_HERE.json
{
  "command": "init",
  "agent_uuid": "YOUR_UUID_HERE",
  "objective": "CONCISE_DENSE_SUMMARY_OF_REQUIREMENTS_AND_GOALS",
  "persona_override": "TARGETED_PERSONA_FOR_THE_SUB_AGENT"
}
EOF
```


Notify User: Once written, notify the user of the generated agent_uuid and instruct them to run /dialogue-loop in their clean session.

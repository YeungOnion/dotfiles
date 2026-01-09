#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///

import json
import sys
from pathlib import Path

PROMPT_MAX_LEN = 500


def main():

    try:
        # Read JSON input from stdin
        input_data = json.loads(sys.stdin.read())
        prompt = input_data.get('prompt', '')


        # Check for LONG: override (using LONG: instead of /long to avoid slash command conflict)
        is_override = prompt.strip().startswith('LONG:')
        if is_override:
            # Strip the LONG: prefix and update the prompt in the input
            prompt = prompt.strip()[5:].strip()  # Remove 'LONG:' and extra whitespace
            input_data['prompt'] = prompt

        # Only check if message is longer than 200 chars
        if len(prompt) < PROMPT_MAX_LEN:
            # Short prompt, just pass through
            output = {
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": ""
                }
            }
            print(json.dumps(output))
            sys.exit(0)

        # List available context files
        context_files = []
        global_context = Path.home() / ".claude" / "context"
        local_context = Path(".claude/context")

        for ctx_dir in [global_context, local_context]:
            if ctx_dir.exists():
                for f in ctx_dir.glob("*.md"):
                    context_files.append(f.name)

        # Build list of available context files for messaging
        context_file_list = ""
        if context_files:
            for f in sorted(set(context_files)):
                context_file_list += f"\n   - @{f}"

        if is_override:
            # User used LONG: override - allow and ask agent about knowledge deposition

            # Add context asking agent to help with knowledge management
            agent_instruction = "\n📝 AGENT INSTRUCTION: This user has sent a long prompt using LONG: override.\n"
            agent_instruction += "After addressing their request, please ask the user:\n"
            agent_instruction += "- Should any of this knowledge be documented in a .claude/context/ file?\n"
            agent_instruction += "- If so, which file would be most appropriate?\n"

            if context_files:
                agent_instruction += f"\nExisting context files:{context_file_list}\n"
            else:
                agent_instruction += "\nNo context files exist yet. Consider suggesting creation of relevant context files.\n"

            agent_instruction += "\nNote: The conversation history may contain additional context that could enrich documentation.\n"

            output = {
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": agent_instruction
                }
            }
            print(json.dumps(output))
        else:
            # Long prompt without override - BLOCK IT

            block_message = f"⛔ Long prompt detected ({len(prompt)} chars)\n\n"
            block_message += "Consider using @ references to context files instead of long explanations.\n"
            if context_files:
                block_message += f"\nAvailable context files:{context_file_list}\n"
            block_message += "\nTo override this check, prefix your prompt with: LONG:\n"

            output = {
                "decision": "block",
                "reason": block_message,
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": ""
                }
            }
            print(json.dumps(output))

        # Success
        sys.exit(0)

    except Exception:
        # Handle any errors gracefully - don't block the user
        sys.exit(0)


if __name__ == '__main__':
    main()

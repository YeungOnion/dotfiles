#!/bin/bash

# Appends a timestamped note to the interview file.
# Usage: interview_note.sh <tag> "<message>"

TAG="$1"
MESSAGE="$2"

# Ensure INTERVIEW_FILE is set
if [[ -z "$INTERVIEW_FILE" ]]; then
  echo "Error: INTERVIEW_FILE environment variable not set." >&2
  exit 1
fi

SKILL_DIR=$(dirname "$(realpath "$0")")

# Get elapsed time
ELAPSED_MINUTES=$("$SKILL_DIR/interview_elapsed.sh")

# Append note to the interview file
echo "[$(printf "%.1f" "$ELAPSED_MINUTES")m][$TAG] $MESSAGE" >> "$INTERVIEW_FILE"

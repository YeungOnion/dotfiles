#!/bin/bash

# Initializes a new interview session file with YAML frontmatter.
# Usage: interview_init.sh "<title>" "<writeup_path>" "<posting_path>" [duration_minutes]

TITLE="$1"
WRITEUP_PATH="$2"
POSTING_PATH="$3"
DURATION="${4:-15}" # Default to 15 minutes if not provided

# Source the interview_env.sh to get INTERVIEWS_DIR
source /home/orion/.agents/skills/interview-me/interview_env.sh

# Generate a slug from the title
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9\s-]/-/g' | sed 's/--+/-/g' | sed 's/^-//' | sed 's/-$//')

# Get current date for filename
DATE=$(date +%Y%m%d)

# Construct filename
FILENAME="${DATE}-${SLUG}.md"
INTERVIEW_FILE="${INTERVIEWS_DIR}/${FILENAME}"

# Get current timestamp
START_TIME=$(date -u +%Y-%m-%dT%H:%M:%S.%6N)

# Create the new interview file with YAML frontmatter
cat <<EOF > "$INTERVIEW_FILE"
---
start: $START_TIME
title: "$TITLE"
writeup_path: "$WRITEUP_PATH"
posting_path: "$POSTING_PATH"
duration: $DURATION
---

EOF

echo "$INTERVIEW_FILE"

# Export INTERVIEW_FILE for subsequent commands in the same session
export INTERVIEW_FILE

#!/bin/bash

# Calculate elapsed time in minutes since the start of the interview
START_TIME=$(yq '.start' "$INTERVIEW_FILE")
CURRENT_TIME=$(date -u +%Y-%m-%dT%H:%M:%S.%6N)

START_SECONDS=$(date -d "$START_TIME" +%s%N)
CURRENT_SECONDS=$(date -d "$CURRENT_TIME" +%s%N)

ELAPSED_NANO=$((CURRENT_SECONDS - START_SECONDS))
ELAPSED_MINUTES=$(echo "scale=2; $ELAPSED_NANO / 1000000000 / 60" | bc)

echo "$ELAPSED_MINUTES"

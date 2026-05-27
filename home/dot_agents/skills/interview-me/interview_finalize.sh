#!/bin/bash

# Finalizes the interview report by appending it to the interview notes file.

# Ensure INTERVIEW_FILE is set
if [[ -z "$INTERVIEW_FILE" ]]; then
  echo "Error: INTERVIEW_FILE environment variable not set." >&2
  exit 1
fi

SKILL_DIR=$(dirname "$(realpath "$0")")

# Get elapsed time
ELAPSED_MINUTES=$("$SKILL_DIR/interview_elapsed.sh")

# Generate final report
REPORT=$(cat <<EOF
# Final Report — $(printf "%.1f" "$ELAPSED_MINUTES")m elapsed

### Overall assessment
<!-- One paragraph, direct. -->


### Strongest signals
<!-- What stood out positively. -->


### Biggest risks / concerns
<!-- Gaps or red flags. -->


### Recommended leveling
<!-- e.g. "strong mid-level", "borderline senior", "not ready" -->


### Topics to study further
<!-- Specific, actionable. -->

EOF
)

# Append report to the interview file
echo "$REPORT" >> "$INTERVIEW_FILE"

# Print the report to stdout as well
echo "$REPORT"

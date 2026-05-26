#!/bin/bash

# Define the base directory for interviews
BASE_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
INTERVIEWS_DIR="$BASE_DIR/.agents/interviews"

# Ensure the interviews directory exists
mkdir -p "$INTERVIEWS_DIR"

# Export the INTERVIEWS_DIR for other scripts
export INTERVIEWS_DIR

#!/usr/bin/env bash
# session-guard.sh - Monitor Claude Code session health
# Part of claudekit plugin
#
# Usage:
#   session-guard.sh          Increment counter and check thresholds
#   session-guard.sh reset    Reset counter (called on SessionStart)
#
# Tracks tool call count per session and warns when context is growing large.
# Prints warnings to stderr which Claude Code displays to the user.

set -euo pipefail

# Generate unique counter ID from working directory
if command -v md5sum &>/dev/null; then
  HASH=$(echo "$PWD" | md5sum | cut -d' ' -f1)
elif command -v md5 &>/dev/null; then
  HASH=$(echo "$PWD" | md5 -q)
else
  HASH=$(echo "$PWD" | cksum | cut -d' ' -f1)
fi

TMPBASE="${TMPDIR:-/tmp}"
COUNTER_FILE="${TMPBASE}/claudekit-${HASH}.count"
STARTED_FILE="${TMPBASE}/claudekit-${HASH}.started"

# Handle reset command (called on SessionStart)
if [ "${1:-}" = "reset" ]; then
  rm -f "$COUNTER_FILE" "$STARTED_FILE" 2>/dev/null
  exit 0
fi

# Track session start time
if [ ! -f "$STARTED_FILE" ]; then
  date +%s > "$STARTED_FILE"
fi

# Increment tool call counter
if [ -f "$COUNTER_FILE" ]; then
  COUNT=$(cat "$COUNTER_FILE")
  COUNT=$((COUNT + 1))
else
  COUNT=1
fi
echo "$COUNT" > "$COUNTER_FILE"

# Calculate session duration in minutes
STARTED=$(cat "$STARTED_FILE")
NOW=$(date +%s)
DURATION_MIN=$(( (NOW - STARTED) / 60 ))

# Warn at thresholds
if [ "$COUNT" -eq 30 ]; then
  echo "[claudekit] ${DURATION_MIN}m, ${COUNT} tool calls. Context is growing. Consider /compact." >&2
fi

if [ "$COUNT" -eq 60 ]; then
  echo "[claudekit] ${DURATION_MIN}m, ${COUNT} tool calls. Large context. Run /claudekit:session-reset to save progress and start fresh." >&2
fi

if [ "$COUNT" -ge 90 ] && [ $(( COUNT % 15 )) -eq 0 ]; then
  echo "[claudekit] ${DURATION_MIN}m, ${COUNT} tool calls. Quality will degrade. Start a new session." >&2
fi

exit 0

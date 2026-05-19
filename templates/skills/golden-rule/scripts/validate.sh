#!/bin/bash
# Example validation script for a Claude Code skill.
# By putting this in a script, you save tokens and ensure deterministic execution.

echo "Validating project structure..."

if [ ! -f "package.json" ] && [ ! -f "pyproject.toml" ]; then
  echo "WARN: No recognized package manager file found."
  exit 1
fi

echo "SUCCESS: Project structure validated."
exit 0

---
name: golden-rule-example
description: >
  An example of an advanced Claude rule (skill) that uses scripts and assets
  for efficient context management. Shows how to structure complex logic outside
  of the main prompt.
user-invocable: true
allowed-tools: Read Write Edit Glob Grep Bash
---

You are executing a golden rule template. This demonstrates how to structure advanced rules using scripts and assets instead of hardcoding everything in the SKILL.md.

## Why this structure?

1. **Scripts (`scripts/`)**: Complex bash or python logic should live in external scripts. This keeps the prompt lean and ensures determinism.
2. **Assets (`assets/`)**: Large markdown templates, JSON schemas, or reference files should live in external assets. You only read them when you actually need them.

## Instructions

When the user asks you to apply the golden rule:

1. Read the template from `assets/template.md`.
2. Run the validation script `bash scripts/validate.sh`.
3. Apply the template structure based on the validation results.

This keeps your initial context window small while giving you access to powerful external logic and references when needed.

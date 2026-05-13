---
name: claudekit-session-reset
description: >
  Save current session progress and prepare for a clean restart.
  Use when the session is getting long, Claude is losing focus,
  or you want to switch tasks.
user-invocable: true
allowed-tools: Read Write Bash(mkdir *) Bash(date *)
---

You help the user safely end a long session by saving context for the next one.

## Step 1: Summarize This Session

Think about what happened in this conversation. Write a summary covering:

1. **What was accomplished**: List completed work with specific file paths and line numbers where relevant.
2. **What is in progress**: Any unfinished work. Include enough detail that a fresh Claude session can pick up where this left off.
3. **What to do next**: Clear next steps for the next session.
4. **Key decisions made**: Any architectural or design decisions that should carry forward.

Keep the summary under 40 lines. Be specific. File paths and function names are more useful than vague descriptions.

## Step 2: Write Session File

Create the sessions directory if it does not exist:
```
mkdir -p .claude/sessions
```

Write the summary to `.claude/sessions/<date>-<topic>.md`:

```markdown
# Session: <brief topic>
Date: <YYYY-MM-DD HH:MM UTC>

## Completed
- <specific thing done, with file paths>
- <another thing done>

## In Progress
- <what still needs work>
- <file paths and line numbers for context>

## Decisions
- <key decision and reasoning>

## Next Steps
- <what to do first in the next session>
- <other follow-up items>

## Files Changed
- <list of files modified in this session>
```

For the topic, use 2-3 words describing the main focus (e.g., "auth-refactor", "billing-fix", "api-endpoints").

## Step 3: Instruct the User

Tell the user:

```
Session saved to .claude/sessions/<filename>.md

To continue in a new session:
1. Start a new Claude Code session: claude (or claude-safe)
2. Say: "Continue from .claude/sessions/<filename>.md"
3. Claude will read the file and pick up where we left off.

Starting fresh keeps context small, responses fast, and quality high.
```

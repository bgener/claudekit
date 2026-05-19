---
name: claudekit-audit
description: >
  Score and evaluate existing Claude Code configuration for token efficiency
  and completeness. Reports problems and suggests improvements. Read-only.
user-invocable: true
allowed-tools: Read Glob Grep Bash(wc *) Bash(cat *)
---

You evaluate Claude Code configuration and report a health score. You do NOT modify any files.

## What to Check

Run every check below. Use actual tools to measure. Do not estimate.

### 1. CLAUDE.md Size

Read `CLAUDE.md` at the project root. Count lines with `wc -l`.

Scoring:
- 1-20 lines: PASS (optimal)
- 21-50 lines: WARN (growing, consider splitting into .claude/rules/)
- 51-100 lines: FAIL (too large, wasting tokens every prompt)
- 100+ lines: CRITICAL (significantly increasing cost and reducing quality)

Calculate token estimate: lines * 4 tokens/line * average_turns_per_session (assume 30).

### 2. Rule Organization

Check if rules exist in `.claude/rules/` directory.

Scoring:
- Rules in `.claude/rules/*.md` with small root CLAUDE.md: PASS
- Everything in one CLAUDE.md: WARN (split into layered files)
- No rules at all: INFO (run /claudekit:init to generate)

Count total lines across all rule files. Report the total always-loaded token cost.

### 3. Rule Quality

Read each rule file. Check for these anti-patterns:

- **Examples in rules**: Lines with code blocks or "for example" in rule files. These belong in docs, not rules. Each example doubles the token cost of that rule.
- **Explanations**: Rules that say "because" or "this is important because". Just state the rule.
- **Generic advice**: "Write clean code", "follow best practices", "use meaningful names". Claude already knows these. They waste tokens.
- **Multi-line rules**: Rules that span multiple lines instead of one line per rule.
- **Duplicated knowledge**: Rules that restate what Claude already knows about a language/framework.

### 4. Permission Profile

Check `.claude/settings.json` for permissions.

Scoring:
- Granular allow/deny lists: PASS
- Only `allow` with no `deny`: WARN (missing safety guardrails)
- No settings.json or no permissions: FAIL (every action asks for confirmation or runs unrestricted)
- Check if destructive commands are blocked (git push, rm -rf, etc.)

### 5. Session Management & Hooks

Check for session guard hook and other hooks in `.claude/settings.json` hooks section.

Scoring:
- Hook exists that monitors session health: PASS
- Hooks use external scripts (`type: "command"`) instead of large inline commands: PASS
- Hooks use scripts from `.claude/scripts/`: PASS
- No session management: WARN (long sessions will degrade without warning)
- Hooks exist but are missing their underlying scripts: FAIL

Check for `.claude/scripts/session-guard.sh` or similar.

### 6. Directory-Level Rules (Monorepo Check)

Detect if this is a monorepo (turbo.json, nx.json, workspaces in package.json, .sln with multiple .csproj).

If monorepo:
- Subdirectory CLAUDE.md files exist: PASS
- All rules in root only: WARN (loading all rules even when working in one package)

If single app: SKIP this check.

### 7. .gitignore Coverage

Check `.gitignore` for:
- `.claude/memory/` (should be ignored, contains personal context)
- `.claude/settings.local.json` (should be ignored, personal overrides)
- `.claude/sessions/` (should be ignored, session summaries)

Scoring:
- All three ignored: PASS
- Some missing: WARN
- No .gitignore or none ignored: FAIL

### 8. Advanced Skills, Scripts, and Assets

Check `.claude/skills/` for custom agent definitions and skills.
Rules and skills can be more than just markdown. Efficient setups use scripts and assets to keep context lean.

Scoring:
- Skills are organized in directories with their own `SKILL.md`: PASS
- Skills use `scripts/` directory for executable logic instead of inline bash: PASS (optimal)
- Skills use `assets/` directory for templates and large context: PASS (optimal)
- `SKILL.md` contains large hardcoded templates/logic instead of external files: WARN (wastes context)
- No skills or advanced rules found: INFO

### 9. Agents

Check `.claude/agents/` for custom agent definitions.

This is informational only. Report what agents exist.

## Output Format

Present results as a clear report:

```
Claude Code Config Audit
========================
Project: <name>
Date: <today>

Score: X/10

[PASS] CLAUDE.md is 14 lines (optimal, ~56 tokens/prompt)
[WARN] No session guard hook detected
[FAIL] .claude/settings.json missing - no permission profile
...

Token Cost Summary
------------------
Always-loaded rules: ~X lines (~Y tokens/prompt)
Estimated cost per 30-turn session: ~Z tokens on rules alone

Recommendations
---------------
1. <most impactful fix first>
2. <second most impactful>
...
```

Scoring guide:
- Start at 10 points
- Each FAIL: -2 points
- Each WARN: -1 point
- Each CRITICAL: -3 points
- Minimum score: 0

Order recommendations by impact. The highest-impact fix goes first.

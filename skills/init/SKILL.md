---
name: claudekit-init
description: >
  Initialize optimal Claude Code configuration for the current project.
  Analyzes the repository and generates CLAUDE.md, rules, permissions,
  hooks, and session management. Run this once per project.
user-invocable: true
allowed-tools: Read Write Edit Glob Grep Bash Agent
argument-hint: "[--non-interactive] [--profile safe|trust|review]"
---

You are a Claude Code configuration expert. Your job is to analyze this software project and generate optimal configuration that minimizes token usage and maximizes development speed.

## Parse Arguments

Check `$ARGUMENTS` for flags:
- `--non-interactive`: Skip all prompts. Use safe profile. Replace existing config (with .bak backup). Write all files without asking.
- `--profile safe|trust|review`: Set permission profile. Default is safe.

If no arguments, run interactively (ask questions, show previews, confirm before writing).

## Step 1: Check for Existing Config

Before doing anything, check if Claude Code config already exists:

```
CLAUDE.md
.claude/
.claude/settings.json
.claude/rules/
```

If config exists:
- **Interactive mode**: Show what exists. Ask: "Claude Code config already exists. Options: (1) Replace with backup, (2) Audit existing config instead, (3) Cancel"
- **Non-interactive mode**: Create `.bak` copies of existing files, then replace.

## Step 2: Analyze the Project

Use the `analyzer` agent to build a complete project profile. Pass it the current working directory.

Wait for the analyzer to finish. Read its full output carefully. You will use every detail from the profile to generate targeted configuration.

## Step 3: Choose Permission Profile

**Interactive mode**: First present the three profile options:

```
Permission profile:

  1. safe (recommended)
     Auto-allow: file reads, edits, builds, tests, git status
     Block: git push, force operations, destructive commands, network writes

  2. trust
     Everything in safe, plus: git commit, package install, non-destructive curl

  3. review
     Confirm everything except file reads. For onboarding or sensitive repos.

Choose [1/2/3]:
```

**Non-interactive mode**: Use the `--profile` argument, default to safe.

## Step 3b: Show Permissions and Let User Customize

After the user picks a profile, show them exactly what will be allowed and denied. Use the project analysis to show only relevant entries (not the full template).

Present it clearly:

```
Working directory: <absolute path to project root>

ALLOWED (no confirmation needed):
  File operations    Read, Edit, Write, Glob, Grep
  Git read-only      git status, git log, git diff, git branch, git show, git blame
  Build              <detected build command, e.g. "pnpm build", "dotnet build">
  Test               <detected test command, e.g. "pnpm test", "dotnet test">
  Lint               <detected lint command, or "none detected">
  GitHub CLI         gh pr view, gh pr list, gh issue view (read-only)
  Safe utilities     ls, find, wc, mkdir, cat, head, tail

BLOCKED (will be denied):
  git push           Prevents accidental pushes to remote
  git reset --hard   Prevents losing uncommitted changes
  git clean          Prevents deleting untracked files
  git rebase         Prevents history rewrites
  git merge          Prevents unintended merges
  rm -rf / rm -r     Prevents recursive deletion
  curl POST/PUT/DEL  Prevents network writes
  gh pr create       Prevents creating PRs without review
  gh pr merge        Prevents merging PRs without review
  npm publish        Prevents accidental package publishing

REQUIRES CONFIRMATION (not in allow or deny, will prompt):
  Everything else    Claude will ask before running
```

Then ask the user if they want to customize:

"These are the default permissions for the safe profile. Would you like to change any of them? Common adjustments:
- Allow git commit (many teams want Claude to commit locally)
- Allow package install (npm install, pip install, etc.)
- Allow git push (if you trust Claude with remote operations)
- Block git commit (if you want full control over commits)
- Allow gh pr create (if you want Claude to create pull requests)

Tell me what to change, or say 'keep as-is' to use these defaults."

Apply whatever the user asks for. This is a conversation, not a menu. The user might say "allow commit and install but keep push blocked" or just "looks good." Handle any reasonable request.

**Non-interactive mode**: Skip customization. Use profile defaults.

## Step 4: Generate Configuration Files

Generate all files below. Follow the rules strictly. Every unnecessary line costs tokens on every prompt for every session in this project.

### 4a. CLAUDE.md (root)

**Maximum 20 lines.** This file loads on every single prompt.

Structure:
```markdown
# <Project Name>

<One sentence: what this project is, language, framework.>
<One sentence: project structure (monorepo? services? single app?)>

## Rules
- <3-7 rules, one per line, specific to THIS project>
```

Rules to include (pick what applies):
- Explicit type declarations if the language supports both implicit and explicit
- The actual test command to run (`pnpm test`, `dotnet test`, `pytest`)
- The actual build command (`pnpm build`, `dotnet build`, `cargo build`)
- The actual lint command if one exists
- Framework-specific convention that Claude might get wrong (e.g., App Router vs Pages Router in Next.js)
- Any naming convention visible from the codebase

Rules to NEVER include:
- "Write clean code" or "follow best practices" (wastes tokens, says nothing)
- "Use meaningful variable names" (Claude already does this)
- Anything Claude already knows about the language/framework
- Examples (put examples in docs/, reference from rules)
- Explanations (just state the rule)

### 4b. .claude/rules/*.md

Create one file per concern. Only create files for concerns the analyzer detected.

**code-style.md** (always create):
- Naming conventions detected from the project (read a few source files if needed to confirm patterns)
- Import ordering if the project has a convention
- Error handling pattern if one is visible
- Maximum 25 lines

**testing.md** (create if testing detected):
- Test framework name and assertion style
- Where test files live
- How to run tests
- Mocking library if detected
- Maximum 20 lines

**database.md** (create only if database/ORM detected):
- ORM name and migration tool
- Migration directory path
- Any conventions visible from existing migrations
- Maximum 15 lines

**ci.md** (create only if CI detected):
- What CI checks (so Claude knows what will be validated)
- How to run the same checks locally
- Maximum 10 lines

**Rule writing rules** (apply to all rule files):
1. One rule per line
2. Imperative mood: "Use X" not "You should use X"
3. No examples in rule files
4. No explanations: "Prefix interfaces with I" not "Prefix interfaces with I because it helps distinguish them from classes"
5. Only project-specific rules. Skip things Claude already knows.
6. No generic advice. Every line must tell Claude something it would not know from reading the code alone.

### 4c. Profile Settings Files

Generate ALL THREE profile settings files. This lets `claude-safe` switch profiles without relying on a nonexistent `--profile` CLI flag.

Read all three templates from the plugin's templates/permissions/ directory:
- `${CLAUDE_PLUGIN_ROOT}/templates/permissions/safe.json`
- `${CLAUDE_PLUGIN_ROOT}/templates/permissions/trust.json`
- `${CLAUDE_PLUGIN_ROOT}/templates/permissions/review.json`

For each template, adapt it to the detected project stack:
- Only include build/test/lint commands that exist in this project
- Add the correct package manager commands
- Add framework-specific safe commands (e.g., `next dev`, `prisma studio`)

Apply the user's permission customizations (from Step 3b) to the chosen profile only. The other two profiles use their template defaults adapted to the stack.

Each settings file must include:
1. **cwd**: The absolute path to the project root
2. **permissions**: The allow/deny lists adapted from the template
3. **hooks**: The session guard hook

Write three files:

**`.claude/settings.safe.json`** - adapted from safe.json template
**`.claude/settings.trust.json`** - adapted from trust.json template
**`.claude/settings.review.json`** - adapted from review.json template

Structure for each:

```json
{
  "cwd": "<absolute path to project root>",
  "permissions": {
    "allow": [
      "<adapted allow list>"
    ],
    "deny": [
      "<adapted deny list>"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/scripts/session-guard.sh"
          }
        ]
      }
    ]
  }
}
```

Do NOT include the `_comment` or `_stack_specific` fields from the template. The output must be valid JSON that Claude Code can parse.

Then write `.claude/settings.json` as a copy of the chosen profile's file (the one the user selected in Step 3). This is what Claude Code loads by default when launched without `claude-safe`.

### 4d. Session Guard Script

Copy the session guard script into the target project:

Read `${CLAUDE_PLUGIN_ROOT}/bin/session-guard.sh` and write it to `.claude/scripts/session-guard.sh` in the target project.

Make sure the scripts directory exists.

### 4e. Directory-Level CLAUDE.md (for monorepos only)

If the analyzer found a monorepo with distinct packages/services, create a CLAUDE.md in each major directory. Maximum 15 lines each. Only include rules specific to that directory.

Example: if there is a `packages/api/` and `packages/web/`:
- `packages/api/CLAUDE.md`: API-specific patterns, endpoint conventions
- `packages/web/CLAUDE.md`: Component patterns, styling approach

Do NOT create these for single-app projects.

### 4f. .gitignore Updates

Check if `.gitignore` exists. If it does, append (if not already present):

```
# Claude Code
.claude/memory/
.claude/settings.local.json
.claude/sessions/
```

If `.gitignore` does not exist, create it with these entries.

## Step 5: Review (Interactive Mode Only)

Show a summary of all generated files with line counts:

```
Generated configuration:

  CLAUDE.md                        14 lines
  .claude/settings.json            copy of chosen profile
  .claude/settings.safe.json       safe profile permissions + hooks
  .claude/settings.trust.json      trust profile permissions + hooks
  .claude/settings.review.json     review profile permissions + hooks
  .claude/rules/code-style.md      18 lines
  .claude/rules/testing.md         12 lines
  .claude/scripts/session-guard.sh session monitor
  .gitignore                       updated (3 lines added)

Total always-loaded rules: 44 lines (~176 tokens/prompt)
```

Ask: "Review any file before finishing? [Enter file name or 'done']"

If the user wants to review, show the file content. Let them request edits. Apply edits and show updated content.

## Step 6: Shell Alias (Interactive Mode Only)

Ask: "Install claude-safe shell alias? This lets you start Claude Code with safe permissions by typing claude-safe. [y/N]"

If yes, tell the user to copy `bin/claude-safe` (or `bin/claude-safe.ps1` on Windows) from the plugin directory to somewhere on their PATH:

For bash/zsh:
```
cp /path/to/claudekit/bin/claude-safe ~/bin/claude-safe
chmod +x ~/bin/claude-safe
```

For PowerShell:
```
Copy-Item /path/to/claudekit/bin/claude-safe.ps1 $HOME\bin\claude-safe.ps1
```

Then use it in any project that has been initialized with /claudekit:init:
```
claude-safe              # safe profile (default)
claude-safe --trust      # trust profile
claude-safe --review     # review profile
```

Do NOT modify shell config files automatically. Just show the user what to add.

## Step 7: Done

Print a summary:

```
Claude Code is configured for <project name>.

Quick start:
  claude                    Start with generated config
  /claudekit:audit            Check config health
  /claudekit:session-reset    Save progress, start fresh

Session guard will warn at 30/60/90 tool calls to manage context size.
```

# How It Works

claudekit is a Claude Code plugin. It contains zero compiled code. Everything is markdown files and shell scripts.

## The Flow

```
You type: /claudekit:init
    |
    v
Claude reads the init skill (a markdown file with instructions)
    |
    v
Claude spawns an analyzer subagent (another markdown file)
    |
    v
Analyzer scans your project using Glob, Grep, Read, Bash
  - Counts files by language
  - Reads package.json, .csproj, go.mod, etc.
  - Checks for test configs, CI files, ORM configs
  - Detects monorepo markers
    |
    v
Analyzer returns a structured project profile
    |
    v
Claude (back in init) uses the profile to:
  - Show you permissions and ask for customization
  - Write CLAUDE.md with project-specific rules
  - Write .claude/rules/*.md split by concern
  - Write .claude/settings.json with permissions + hooks
  - Copy session-guard.sh into your project
  - Update .gitignore
    |
    v
You review and approve. Done.
```

## Why Skills Instead of Code?

A skill is a markdown prompt. Claude reads it and follows the instructions using its own tools. This means:

- **No build step.** No dependencies. No runtime. Just markdown and bash.
- **Claude is the analyzer.** It reads your code better than any static file scanner. It understands import patterns, naming conventions, and framework idioms.
- **Easy to modify.** Change the behavior by editing a markdown file.
- **Transparent.** Read the skill to understand exactly what the plugin does. No hidden logic.

The tradeoff: running init costs tokens (~15K-25K). This is a one-time cost per project. It pays for itself in 2-3 sessions through reduced rule overhead.

## Why a Separate Analyzer Agent?

The analyzer reads many files. If this ran in your main conversation, all those file contents would stay in context for the rest of the session. By running as a subagent, the analysis stays in a separate context. Only the final profile report comes back.

## Why Split Rules into Multiple Files?

A single 300-line CLAUDE.md loads entirely on every prompt. Split into:
- Root `CLAUDE.md` (20 lines, always loaded)
- `.claude/rules/*.md` (30 lines each, always loaded but organized)
- Subdirectory `CLAUDE.md` (15 lines, only loaded in that directory)

Total loaded tokens drop from ~1,200 to ~600 per prompt. Over 30 turns, that's 18,000 tokens saved.

## Plugin Components

| Component | Files | What it does |
|-----------|-------|-------------|
| Skills | `skills/*/SKILL.md` | Prompts that tell Claude what to do when you run a command |
| Agents | `agents/*.md` | Specialized subagents (the project analyzer) |
| Hooks | `hooks/hooks.json` | Auto-run scripts (session guard fires after every tool call) |
| Scripts | `bin/*.sh` | Shell scripts (session counter, safe launcher) |
| Templates | `templates/permissions/*.json` | Reference data for permission generation |

For details on each component's format, see [CONTRIBUTING.md](../CONTRIBUTING.md).

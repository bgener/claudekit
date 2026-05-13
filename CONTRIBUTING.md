# Contributing to claudekit

## How the Plugin Works

This is a Claude Code plugin. It contains no compiled code. Everything is markdown files (skills, agents) and shell scripts (hooks, launchers). Claude reads the markdown and follows the instructions using its built-in tools.

The quality of this plugin depends on the quality of the prompts in the skill and agent files.

## Project Structure

```
claudekit/
  .claude-plugin/
    plugin.json              # Plugin manifest (name, version, description)
  skills/
    init/SKILL.md            # /claudekit:init - main setup
    audit/SKILL.md           # /claudekit:audit - config scoring
    session-reset/SKILL.md   # /claudekit:session-reset - save & restart
  agents/
    analyzer.md              # Project analysis subagent
  hooks/
    hooks.json               # Session guard hook (PostToolUse + SessionStart)
  bin/
    session-guard.sh         # Session counter script
    claude-safe              # Bash launcher
    claude-safe.ps1          # PowerShell launcher
  templates/
    permissions/
      safe.json              # Permission template with stack-specific sections
      trust.json
      review.json
  docs/                      # User-facing documentation
```

## Component Formats

### Skills (skills/*/SKILL.md)

Skills are markdown files with YAML frontmatter. When a user types `/claudekit:<name>`, Claude loads the SKILL.md and follows it as instructions.

```yaml
---
name: skill-name
description: When Claude should use this skill
user-invocable: true              # Show in slash command menu
allowed-tools: Read Write Bash    # Pre-approve tools (no user confirmation)
argument-hint: "[--flags]"        # Shown in autocomplete
---

The body is a prompt. Claude follows these instructions step by step.
It can use any tool listed in allowed-tools without asking the user.
```

### Agents (agents/*.md)

Agents are subagents Claude can spawn. Same format as skills but with agent-specific frontmatter:

```yaml
---
name: agent-name
model: sonnet                     # Which model (sonnet is cheaper/faster)
maxTurns: 30                      # Limit how long the agent runs
tools: Read Glob Grep Bash(git *) # Restricted tool access
---

Agent instructions here. The agent runs in a separate context.
Only its final output comes back to the main conversation.
```

### Hooks (hooks/hooks.json)

Shell commands that run on events. Uses `${CLAUDE_PLUGIN_ROOT}` to reference scripts relative to the plugin install location.

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "bash \"${CLAUDE_PLUGIN_ROOT}/bin/session-guard.sh\""
      }]
    }],
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "bash \"${CLAUDE_PLUGIN_ROOT}/bin/session-guard.sh\" reset"
      }]
    }]
  }
}
```

### Permission Templates (templates/permissions/*.json)

Reference data that the init skill reads during generation. Each template has:

- `cwd`: Placeholder (init skill replaces with actual project path)
- `permissions.allow`: Base list of allowed operations
- `permissions.deny`: Base list of blocked operations
- `_stack_specific`: Per-language additions (e.g., Python gets `pytest`, .NET gets `dotnet test`)
- `_comment`: Explanation (not included in generated output)

The init skill reads the template, picks stack-specific entries matching the detected project, applies user customizations, and writes a clean settings.json.

## How to Test Changes

1. Load the plugin locally:
   ```bash
   claude --plugin-dir /path/to/claudekit
   ```

2. Run the skill you changed:
   ```
   /claudekit:init
   /claudekit:audit
   /claudekit:session-reset
   ```

3. Reload after changes without restarting:
   ```
   /reload-plugins
   ```

4. Test on different project types (TypeScript, Python, C#, Go).

## Adding a New Skill

1. Create `skills/<skill-name>/SKILL.md`
2. Add YAML frontmatter with name, description, allowed-tools
3. Write the prompt body
4. Test with `claude --plugin-dir ./`
5. Update README.md and docs

## Improving the Analyzer

The analyzer agent (`agents/analyzer.md`) detects project characteristics. To support a new language or framework:

1. Add detection logic to the relevant section in the analyzer
2. Add the language/framework to the output format
3. Update the init skill to generate rules for the new detection
4. Add stack-specific entries to permission templates if needed
5. Update the "Supported Stacks" section in README.md

## Rule Writing Principles

When changing how the init skill generates rules, follow these:

1. One rule per line
2. Imperative mood ("Use X" not "You should use X")
3. No examples in rule files (reference docs instead)
4. No explanations ("Prefix interfaces with I" not "Prefix interfaces with I because...")
5. Only project-specific rules. Skip what Claude already knows.

## Pull Requests

1. Fork the repository
2. Create a branch for your change
3. Test on at least two different project types
4. Submit a PR with a clear description of what changed and why

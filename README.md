# claudekit

Golden path setup for Claude Code.

Use it when you want the same Claude Code baseline across projects: short rules,
safe permissions, repeatable launch profiles, and a clean way to stop long
sessions before they drift.

## What it does

`/claudekit:init` analyzes a repo and generates:

```text
CLAUDE.md
.claude/
  settings.json
  settings.safe.json
  settings.trust.json
  settings.review.json
  rules/
    code-style.md
    testing.md
    database.md
    ci.md
  scripts/session-guard.sh
```

The goal is boring on purpose: every project gets the same operating model.

- **Small root prompt:** `CLAUDE.md` stays under 20 lines.
- **Focused rules:** `.claude/rules/*.md` uses one rule per line, no examples, no generic advice.
- **Safe execution:** destructive commands are blocked by default.
- **Project-aware commands:** build, test, lint, package manager, and stack commands are detected from the repo.
- **Profile switching:** run the same project in `safe`, `trust`, or `review` mode.
- **Session control:** warn at 30, 60, and 90 tool calls.
- **Config audit:** score an existing Claude setup and find prompt bloat.

## Install

Inside Claude Code:

```text
/plugin marketplace add bgener/claudekit
/plugin install claudekit
```

Or test locally:

```bash
git clone https://github.com/bgener/claudekit.git ~/claudekit
cd ~/your-project
claude --plugin-dir ~/claudekit
```

## Initialize a project

```text
/claudekit:init
```

The init flow:

1. Scans the project with a separate analyzer agent.
2. Detects language, framework, test runner, package manager, CI, database tooling, and existing Claude config.
3. Lets you pick a permission profile.
4. Shows what will be allowed, blocked, and left for confirmation.
5. Writes the Claude Code config files.

For non-interactive setup:

```text
/claudekit:init --non-interactive --profile safe
```

## Permission profiles

| Profile | Use it for | Auto-allows | Blocks |
|---|---|---|---|
| `safe` | Daily development | reads, edits, builds, tests, lint, git read commands | `git push`, force resets, recursive delete, network writes |
| `trust` | Experienced local work | safe plus commits, package install, non-destructive downloads | remote writes and destructive commands |
| `review` | Onboarding or sensitive repos | reads and read-only git/GitHub commands | destructive and shared-state commands |

`settings.json` is the default profile for plain `claude`.

All profiles are also written separately:

```text
.claude/settings.safe.json
.claude/settings.trust.json
.claude/settings.review.json
```

## Run with a profile

Use the launcher from `bin/`:

```bash
claude-safe
claude-safe --trust
claude-safe --review
```

PowerShell:

```powershell
claude-safe.ps1
claude-safe.ps1 -Trust
claude-safe.ps1 -Review
```

The launcher loads the selected settings file directly. It does not merge with
`.claude/settings.json`.

## End long sessions

The session guard runs after every tool call.

| Tool calls | Action |
|---:|---|
| 30 | Consider `/compact` |
| 60 | Run `/claudekit:session-reset` |
| 90+ | Start a new session |

Save a session:

```text
/claudekit:session-reset
```

It writes a short resume file to:

```text
.claude/sessions/<date>-<topic>.md
```

Start a new Claude Code session and continue from that file.

## Audit an existing setup

```text
/claudekit:audit
```

The audit checks:

- root `CLAUDE.md` size
- rule organization
- generic or bloated rules
- permission coverage
- session guard hook
- `.gitignore` coverage
- monorepo rule placement

Use this when a prompt started small and slowly turned into a local wiki.

## Team rollout

Commit this to a repo that should use claudekit:

```json
{
  "enabledPlugins": ["claudekit@bgener/claudekit"],
  "extraKnownMarketplaces": {
    "claudekit": {
      "source": { "source": "github", "repo": "bgener/claudekit" }
    }
  }
}
```

Then run:

```text
/claudekit:init
```

Commit the generated profiles and rule files after review.

## Commands

| Command | Purpose |
|---|---|
| `/claudekit:init` | Generate Claude Code config for a repo |
| `/claudekit:audit` | Score existing Claude Code config |
| `/claudekit:session-reset` | Save progress and restart with clean context |

## Best practices encoded

- Keep root `CLAUDE.md` under 20 lines.
- Split rules by concern instead of building one long prompt.
- Keep rule files short: one rule per line, imperative, no examples.
- Put examples in docs, not always-loaded agent rules.
- Generate permissions from the actual project stack.
- Block remote writes and destructive commands unless a human changes the profile.
- Use `review` mode for unfamiliar repos.
- Use `trust` only when local commits and package installs are acceptable.
- Reset or compact long sessions instead of pushing through degraded context.
- Audit Claude config like any other project artifact.

## License

Apache 2.0. See [LICENSE](LICENSE).

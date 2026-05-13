# Getting Started

## Prerequisites

- Claude Code CLI installed (`npm install -g @anthropic-ai/claude-code`)
- A software project (any language)

## Install the Plugin

### For yourself

```bash
# Inside any Claude Code session:
/plugin marketplace add bgener/claudekit
/plugin install claudekit
```

Done. The plugin is now available in every project.

### For your team

Add to your repo's `.claude/settings.json` and commit it:

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

Every developer who clones the repo gets the plugin automatically. No individual setup needed.

### For trying it out (no install)

```bash
git clone https://github.com/bgener/claudekit.git ~/claudekit
cd ~/your-project
claude --plugin-dir ~/claudekit
```

## Initialize Your Project

```bash
cd ~/your-project
claude
```

```
/claudekit:init
```

### What happens

**1. Analysis** (10-30 seconds). Claude spawns a subagent that scans your project. It reads your package.json, .csproj, go.mod, CI configs, test configs, and directory structure. It does not run your code or make network calls.

**2. Profile selection.** You pick safe, trust, or review. See [Permission Profiles](permission-profiles.md) for details.

**3. Permission review.** Claude shows you what will be allowed and blocked, using your actual project commands (not generic ones). Example:

```
Working directory: /home/dev/my-app

ALLOWED (no confirmation needed):
  File operations    Read, Edit, Write, Glob, Grep
  Git read-only      git status, git log, git diff, git show, git blame
  Build              pnpm build
  Test               pnpm test
  Lint               pnpm lint
  GitHub CLI         gh pr view, gh pr list (read-only)

BLOCKED (will be denied):
  git push           Prevents accidental pushes to remote
  git reset --hard   Prevents losing uncommitted changes
  rm -rf / rm -r     Prevents recursive deletion
  gh pr create       Prevents creating PRs without review

REQUIRES CONFIRMATION:
  Everything else    Claude asks before running
```

Claude asks if you want to change anything. Common adjustments: "also allow git commit", "allow package install", "block git checkout too." Just say what you want in plain English. Or say "keep as-is" to use the defaults.

**4. File generation.** Claude writes:

- `CLAUDE.md` (under 20 lines)
- `.claude/settings.json` (copy of your chosen profile, loaded by plain `claude`)
- `.claude/settings.safe.json` (safe profile, stack-specific)
- `.claude/settings.trust.json` (trust profile, stack-specific)
- `.claude/settings.review.json` (review profile, stack-specific)
- `.claude/rules/code-style.md`
- `.claude/rules/testing.md` (if tests detected)
- `.claude/rules/database.md` (if ORM detected)
- `.claude/rules/ci.md` (if CI detected)
- `.claude/scripts/session-guard.sh`
- `.gitignore` updates

All three profile files are committed to the repo. Your team can switch profiles without re-running init.

**5. Review.** You see line counts and token cost estimates. You can review or edit any file.

## After Init

### Launch with the default profile

```bash
claude
```

Loads `.claude/settings.json` (whichever profile you chose as default during init).

### Launch with a specific profile

Install `claude-safe` from the plugin's `bin/` directory:

```bash
# Copy to somewhere on your PATH
cp ~/claudekit/bin/claude-safe ~/bin/claude-safe
chmod +x ~/bin/claude-safe
```

Then use it in any initialized project:

```bash
claude-safe              # safe profile
claude-safe --trust      # trust profile
claude-safe --review     # review profile
```

`claude-safe` loads `.claude/settings.<profile>.json` directly. It does not merge with `.claude/settings.json`. What you pick is exactly what runs.

See [Permission Profiles](permission-profiles.md) for when to use each profile.

### Session guard

The session guard runs in the background. When you see a warning about context size:

- At 30 calls: run `/compact` to compress prior messages
- At 60 calls: run `/claudekit:session-reset` to save progress, then start a new session

See [Session Management](session-management.md) for details.

## Full Example

```bash
cd ~/projects/my-api
claude

> /claudekit:init

# Claude detects: TypeScript, Express, Jest, GitHub Actions, Prisma
# You pick: safe profile
# You customize: "also allow git commit"
# Claude generates config
# You review and approve

> Fix the authentication bug in src/auth/middleware.ts

# ... work happens ...

# [claudekit] 12m, 30 tool calls. Context is growing. Consider /compact.

> /compact

# ... more work ...

# [claudekit] 25m, 60 tool calls. Run /claudekit:session-reset to save progress.

> /claudekit:session-reset

# Session saved to .claude/sessions/2025-04-19-auth-fix.md
# Start a new session:

claude
> Continue from .claude/sessions/2025-04-19-auth-fix.md
```

## Audit Without Init

You can audit any project's existing Claude Code config, even without running init first:

```
/claudekit:audit
```

This is a good way to see what claudekit would improve before committing to it.

## Updating Config

Re-run init anytime:

```
/claudekit:init
```

It detects existing config and asks: replace (with backup), audit instead, or cancel.

## Uninstalling

Remove generated files from your project:

```bash
rm CLAUDE.md
rm -rf .claude/rules/ .claude/scripts/
rm .claude/settings.json .claude/settings.safe.json .claude/settings.trust.json .claude/settings.review.json
```

Remove the plugin:

```
/plugin uninstall claudekit
```

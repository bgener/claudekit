# claudekit

Stop wasting tokens on bloated CLAUDE.md files, permission prompts, and sessions that go off the rails.

## The Problem

Most Claude Code setups look like this:

- A 200-line CLAUDE.md that loads on every prompt, costing 800+ tokens per turn
- No permission config, so Claude asks "allow this?" on every bash command
- No session management, so quality degrades after 30 minutes and Claude starts hallucinating
- Every new project gets the same manual setup ritual: write rules, configure permissions, figure out what to allow

Claude Code has a built-in `/init` that creates a basic CLAUDE.md. That covers step 1 of 5. Harness does all 5 automatically.

## What Harness Does

Run one command. Claude analyzes your project and generates:

| What | Why |
|------|-----|
| `CLAUDE.md` under 20 lines | Every line costs tokens on every prompt. Less is more. |
| `.claude/rules/*.md` split by concern | Only loads what's relevant. No 300-line monolith. |
| `.claude/settings.json` with permissions | Auto-allow builds/tests, block git push/rm -rf. No more "allow?" prompts. |
| Session guard hook | Warns at 30/60/90 tool calls before quality degrades. |
| `.gitignore` updates | Keeps personal Claude data out of version control. |

**Token cost to run init**: ~15K-25K tokens (one time). Pays for itself in 2-3 sessions through reduced rule overhead.

## Before and After

**Before** (typical hand-written CLAUDE.md, 180 lines):

```markdown
# My Project

This is a TypeScript project using Next.js 14 with App Router...

## Code Style
- Always use TypeScript strict mode
- Use explicit return types on all functions
- Prefer const over let
- Use meaningful variable names
- Follow the DRY principle
- Write clean, maintainable code
...120 more lines of rules Claude already knows...
```

**After** (claudekit-generated, 14 lines):

```markdown
# my-app

Next.js 14 (App Router) with TypeScript. Monorepo with 3 packages (turborepo).

## Rules
- Run `pnpm test` before reporting work as done
- Run `pnpm lint` to check formatting
- Use explicit return types on exported functions
- Co-locate tests in `__tests__/` next to source files
- Use Prisma for all database access. Migrations in `prisma/migrations/`
```

The rest goes in `.claude/rules/code-style.md` and `.claude/rules/testing.md`, which are always loaded but organized by concern. Framework-specific rules go in subdirectory `CLAUDE.md` files that only load when Claude works in that directory.

**Token savings**: ~600 tokens/prompt instead of ~1,200. Over a 30-turn session, that's 18,000 fewer tokens.

## Quick Start

### Try it (30 seconds)

```bash
git clone https://github.com/bgener/claudekit.git ~/claudekit
cd ~/your-project
claude --plugin-dir ~/claudekit
```

Then type:

```
/claudekit:init
```

Claude analyzes your project, shows you the permission breakdown, and generates everything. You review before it writes.

### Install permanently

```bash
# Inside any Claude Code session:
/plugin marketplace add bgener/claudekit
/plugin install claudekit
```

Now `/claudekit:init`, `/claudekit:audit`, and `/claudekit:session-reset` work in every project.

### Roll out to a team

Add to your repo's `.claude/settings.json`:

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

Commit this file. Every developer who clones the repo gets the plugin automatically.

## Permission Profiles

During init, you pick a profile and see exactly what it allows and blocks. You can customize before applying.

### Safe (default)

For daily development. Claude codes freely but cannot change shared state.

| Auto-allowed | Blocked | Asks first |
|---|---|---|
| Read, edit, write files | `git push` | `git commit` |
| `git status/log/diff` | `git reset --hard` | `npm install` |
| Build, test, lint | `rm -rf` | `docker run` |
| `gh pr view/list` | `gh pr create/merge` | Everything else |
| `ls`, `find`, `cat` | `curl POST/PUT/DELETE` | |

### Trust

Safe plus: `git commit`, package install, `curl` GET. For experienced developers.

### Review

Only reads auto-allowed. Everything else asks. For onboarding or sensitive repos.

### Customization

After picking a profile, the plugin shows every permission and lets you change them. Want Claude to commit? Allow it. Want to block `git checkout` too? Block it. The generated `settings.json` reflects your choices.

You can also edit `.claude/settings.json` manually anytime.

## Session Guard

Long sessions cost more and produce worse results. The session guard tracks tool calls and warns:

- **30 calls**: "Consider /compact"
- **60 calls**: "Save progress and start fresh"
- **90+ calls**: "Quality is degrading"

Zero token cost. Runs as a bash script outside Claude's context.

When the warning fires, run `/claudekit:session-reset` to save your progress:

```
/claudekit:session-reset
```

This writes a summary to `.claude/sessions/`. Start a new session and say:

```
Continue from .claude/sessions/2025-04-19-auth-fix.md
```

Claude picks up where you left off without carrying the full conversation history.

## Audit Your Existing Config

Already have a CLAUDE.md? Score it:

```
/claudekit:audit
```

```
Claude Code Config Audit
========================
Score: 4/10

[FAIL] CLAUDE.md is 187 lines (~748 tokens/prompt, ~22,440 tokens/session)
[WARN] All rules in root CLAUDE.md, none in .claude/rules/
[FAIL] No permission profile in .claude/settings.json
[WARN] No session guard hook
[PASS] .gitignore covers .claude/memory/

Recommendations:
1. Split CLAUDE.md into layered rules (saves ~400 tokens/prompt)
2. Add permission profile to stop confirmation prompts
3. Add session guard to prevent quality degradation
```

## Commands

| Command | What it does |
|---------|-------------|
| `/claudekit:init` | Analyze project, generate all config |
| `/claudekit:audit` | Score existing config, report token waste |
| `/claudekit:session-reset` | Save session progress, prepare clean restart |

## Generated Files

```
your-project/
  CLAUDE.md                          # Under 20 lines
  .claude/
    settings.json                    # Your chosen default profile (loaded by plain `claude`)
    settings.safe.json               # Safe profile, stack-specific
    settings.trust.json              # Trust profile, stack-specific
    settings.review.json             # Review profile, stack-specific
    rules/
      code-style.md                  # Naming, imports, patterns
      testing.md                     # Test conventions (if detected)
      database.md                    # ORM rules (if detected)
      ci.md                          # CI awareness (if detected)
    scripts/
      session-guard.sh               # Session health monitor
```

All three profile files are committed to the repo. Switch profiles with `claude-safe`:

```bash
claude-safe              # safe (default)
claude-safe --trust      # trust
claude-safe --review     # review
```

## Supported Stacks

The analyzer detects and generates rules for:

**Languages**: TypeScript, JavaScript, C#, Python, Go, Rust, Java, Ruby, PHP, Swift, Kotlin

**Frameworks**: Next.js, React, Vue, Angular, ASP.NET, FastAPI, Django, Express, NestJS, Gin, Actix, Spring Boot, Rails, and more

**Testing**: Jest, Vitest, xUnit, pytest, Go test, Cargo test, RSpec, Playwright, Cypress

**CI/CD**: GitHub Actions, Azure DevOps, GitLab CI, Jenkins, CircleCI

**Databases**: Prisma, TypeORM, Entity Framework, SQLAlchemy, GORM, Diesel, ActiveRecord

## Documentation

- [Getting Started](docs/getting-started.md) - Detailed walkthrough with examples
- [Permission Profiles](docs/permission-profiles.md) - Full reference for each profile
- [Session Management](docs/session-management.md) - How and when to manage sessions
- [Architecture](docs/architecture.md) - How the plugin works internally

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache 2.0. See [LICENSE](LICENSE).

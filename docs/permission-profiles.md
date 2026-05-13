# Permission Profiles

Full reference for what each profile allows and blocks.

The README has a quick comparison table. This doc has the complete lists.

## How Permissions Work

Claude Code permissions have three buckets:

- **allow**: Runs without asking. No confirmation prompt.
- **deny**: Always blocked. Claude cannot run them.
- **Everything else**: Claude asks you for confirmation.

Permissions use pattern matching. `Bash(git status*)` matches any command starting with `git status`. `Bash(git push*)` blocks `git push`, `git push origin main`, `git push --force`, etc.

## Profile Files

When you run `/claudekit:init`, it generates three settings files in your project:

```
.claude/
  settings.json           # your chosen default profile (loaded by plain `claude`)
  settings.safe.json      # safe profile
  settings.trust.json     # trust profile
  settings.review.json    # review profile
```

All three files are fully formed and stack-specific. They include your project's actual build, test, and lint commands, not generic placeholders. Commit all of them. They are project config, not personal data.

### Switching profiles

Use `claude-safe` from the plugin's `bin/` directory:

```bash
claude-safe              # safe profile (default)
claude-safe --trust      # trust profile
claude-safe --review     # review profile
```

`claude-safe` loads the matching `.claude/settings.<profile>.json` file directly. It uses `--setting-sources "user"` to skip `.claude/settings.json` entirely, so the profile you pick is the only source of project-level permissions. Nothing merges or conflicts.

Without `claude-safe`, running plain `claude` loads `.claude/settings.json`, which is whichever profile you chose as default during init.

### Changing the default

To change which profile `claude` uses by default, copy the profile file over `settings.json`:

```bash
cp .claude/settings.trust.json .claude/settings.json
```

### When to use each

| Situation | Profile |
|---|---|
| Normal daily development | `safe` |
| You want Claude to commit and install packages | `trust` |
| Onboarding a new team member | `review` |
| Auditing an unfamiliar codebase | `review` |
| Pairing session where you want full control | `review` |
| CI automation or scripted runs | `trust` |

## Working Directory

All profiles set `cwd` to lock Claude to the project root:

```json
{
  "cwd": "/home/dev/my-project"
}
```

Claude cannot read or modify files outside this directory.

## Safe Profile

The default. Designed for daily development where you want speed without risk.

### Philosophy

Let Claude do everything a developer does during a normal coding session. Block anything that changes shared state (remote repos, published packages) or is hard to undo (force resets, recursive deletes).

### Allowed (runs without asking)

**File operations** (always safe in a git repo, you can revert any change):
- `Read`, `Edit`, `Write`, `Glob`, `Grep`, `NotebookEdit`

**Agent and task management**:
- `Agent`, `TaskCreate`, `TaskUpdate`, `TaskGet`

**Git read operations** (never change state):
- `git status`, `git log`, `git diff`, `git branch`, `git show`, `git blame`, `git stash list`, `git rev-parse`, `git remote`

**Build, test, lint** (project-specific, added based on detected stack):
- npm/pnpm/yarn/bun: `npm run *`, `pnpm run *`, `npx *`, `node *`, `tsc *`
- .NET: `dotnet build`, `dotnet test`, `dotnet run`, `dotnet restore`
- Python: `python *`, `pytest *`, `python -m pytest *`
- Go: `go build`, `go test`, `go run`, `go vet`
- Rust: `cargo build`, `cargo test`, `cargo run`, `cargo check`, `cargo clippy`
- Make: `make *`

**GitHub CLI read operations**:
- `gh pr view`, `gh pr list`, `gh pr diff`, `gh pr checks`
- `gh issue view`, `gh issue list`
- `gh api` (GET only)

**Safe utilities**:
- `ls`, `find`, `wc`, `which`, `head`, `tail`, `mkdir`, `pwd`, `echo`, `cat`

### Blocked (always denied)

**Destructive git**:
- `git push` (changes remote, visible to team)
- `git reset --hard` (loses uncommitted changes)
- `git checkout --` (discards file changes)
- `git clean` (deletes untracked files)
- `git rebase` (rewrites history)
- `git merge` (can cause conflicts)
- `git branch -D` / `git branch -d` (deletes branches)

**Destructive filesystem**:
- `rm -rf` / `rm -r` (recursive delete)
- `rmdir` (directory delete)
- `chmod` / `chown` (permission changes)

**Network writes**:
- `curl -X POST/PUT/PATCH/DELETE` (modifies external systems)

**GitHub CLI write operations**:
- `gh pr create/merge/close/comment` (changes shared state)
- `gh issue create/close` (changes shared state)
- `gh api --method POST/PUT/PATCH/DELETE` (modifies remote)

**Package publishing**:
- `npm publish`, `dotnet nuget push`, `cargo publish`, `pip upload`, `twine upload`, `gem push`

### Requires confirmation

Everything not in allow or deny. Examples:
- `git commit` (not destructive, but not in safe allow list)
- `npm install` (modifies node_modules)
- `docker run` (if Docker not in detected stack)
- Any unrecognized bash command

## Trust Profile

For experienced developers who want fewer prompts.

### Added over Safe

**Git write (local only)**:
- `git add`, `git commit`, `git stash`
- `git checkout -b` / `git switch -c` (create branches)
- `git switch` / `git checkout` (switch branches)

**Package install**:
- `npm install`, `pnpm add`, `pnpm install`
- `yarn add`, `yarn install`
- `bun add`, `bun install`
- `pip install`, `pip3 install`, `uv add`
- `go get`, `go mod`
- `cargo add`
- `dotnet add`

**Non-destructive network**:
- `curl -s` / `curl --silent` / `curl -f` (GET requests)
- `wget -q` (downloads)

### Still blocked

Same deny list as safe. Trust still blocks:
- `git push` (remote changes)
- `git reset --hard` (destructive)
- `rm -rf` (destructive)
- `curl POST/PUT/DELETE` (network writes)
- Package publishing
- GitHub CLI write operations

## Review Profile

For onboarding, auditing, or when you want full visibility.

### Allowed (runs without asking)

Only read operations:
- `Read`, `Glob`, `Grep`
- `git status`, `git log`, `git diff`, `git show`, `git blame`, `git branch --list`
- `ls`, `wc`, `which`, `head`, `tail`, `pwd`, `cat`
- `gh pr view`, `gh issue view`

### Blocked

Same deny list as safe.

### Requires confirmation

Everything else. Every file edit, every build command, every git operation beyond reads. Claude asks before doing anything that modifies state.

## Customization During Init

When you run `/claudekit:init`, after selecting a profile, Claude shows the full permission breakdown and asks if you want to change anything.

Common adjustments:
- "Allow git commit" (move to allowed)
- "Allow package install" (add npm install, pip install, etc.)
- "Allow git push" (move from blocked to allowed)
- "Block git commit" (add to denied)
- "Allow gh pr create" (move from blocked to allowed)

Just tell Claude what you want in plain English. It adjusts the permissions and writes the result to `settings.json`.

## Manual Customization

Edit any of the profile files directly. Changes take effect on the next `claude` or `claude-safe` launch.

To add `git commit` to the safe profile:

```json
// .claude/settings.safe.json
{
  "permissions": {
    "allow": [
      "Bash(git commit*)"
    ]
  }
}
```

To block a command that is currently in the allow list, move it to deny:

```json
{
  "permissions": {
    "deny": [
      "Bash(git checkout*)"
    ]
  }
}
```

If you edit a profile file, also copy it to `settings.json` if it is your default:

```bash
cp .claude/settings.safe.json .claude/settings.json
```

### Pattern syntax

- `*` matches anything after the prefix
- `Bash(git push*)` matches `git push`, `git push origin`, `git push --force`, etc.
- `Bash(git push --force*)` matches only force pushes, not plain `git push`
- Tool names without `Bash()`: `Read`, `Edit`, `Write`, `Glob`, `Grep`, `Agent`

## Stack-Specific Permissions

The init skill reads the analyzer's project profile and only includes relevant commands. A Python project will have:

```json
"allow": [
  "Bash(python *)",
  "Bash(pytest *)",
  "Bash(python -m pytest*)"
]
```

Not:
```json
"allow": [
  "Bash(npm run *)",
  "Bash(dotnet build*)",
  "Bash(cargo test*)"
]
```

This keeps the permission list focused and readable.

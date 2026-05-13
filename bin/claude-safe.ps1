# claude-safe.ps1 - Launch Claude Code with safe permissions
# Part of claudekit plugin
#
# Usage:
#   claude-safe                 Use current directory
#   claude-safe C:\my\project   Use specified directory
#   claude-safe -Trust          Use trust profile

param(
    [ValidateSet('safe', 'trust', 'review')]
    [string]$Profile = 'safe',

    [Parameter(Position = 0)]
    [string]$Directory,

    [switch]$Trust,
    [switch]$Review,
    [switch]$Help
)

if ($Help) {
    @"
Usage: claude-safe [-Profile safe|trust|review] [directory]

Launch Claude Code with a permission profile.

Profiles:
  safe    (default) Auto-allow reads, edits, builds, tests.
          Block pushes, force operations, destructive commands.
  trust   Safe plus git commit, package install, curl GET.
  review  Confirm everything except reads. For onboarding.

Examples:
  claude-safe                          Current directory, safe profile
  claude-safe -Trust C:\my\project     Trust profile in C:\my\project
"@
    return
}

# Handle switch shortcuts
if ($Trust) { $Profile = 'trust' }
if ($Review) { $Profile = 'review' }

$TargetDir = if ($Directory) { $Directory } else { Get-Location }

# Check Claude Code is installed
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Error "Claude Code CLI not found. Install: npm install -g @anthropic-ai/claude-code"
    exit 1
}

# Check profile settings file exists
$SettingsFile = "$TargetDir\.claude\settings.$Profile.json"
if (-not (Test-Path $SettingsFile)) {
    Write-Error "No claudekit settings found for profile '$Profile' in $TargetDir. Run /claudekit:init inside a Claude Code session first."
    exit 1
}

# Clear previous session counters
$Hash = [System.BitConverter]::ToString(
    [System.Security.Cryptography.MD5]::Create().ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes($TargetDir)
    )
).Replace('-', '').ToLower()

$TmpBase = $env:TEMP
Remove-Item "$TmpBase\claudekit-$Hash.count" -ErrorAction SilentlyContinue
Remove-Item "$TmpBase\claudekit-$Hash.started" -ErrorAction SilentlyContinue

# Launch Claude Code with the profile settings file
# --setting-sources "user" skips .claude/settings.json so the profile file
# is the sole source of project-level permissions (not merged/additive)
Set-Location $TargetDir
claude --setting-sources "user" --settings $SettingsFile

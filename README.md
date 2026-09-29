# Claude Notifier

macOS notifications for Claude Code — fires when a turn ends and when Claude
needs your input.

## Install

```bash
bash ~/.claude/claude-notifier/install.sh
```

macOS prompts you to grant notification permission to "Claude Notifier" the
first time — click **Allow**.

## What you get

- **Turn-end notification** (`Stop` hook)
  - Title: `Claude · <project>`
  - Subtitle: `<branch>` or `<branch> ● <N> files` if there are uncommitted changes
  - Message: last assistant reply (truncated)
  - Sound: `Glass` on success, `Basso` if the last reply mentions error/failed/blocked
- **AFK notification** (`Notification` hook)
  - Title: `Claude needs you · <project>` (tool name appended for permission prompts)
  - Sound: `Hero`; bypasses Do Not Disturb
- Clicking either focuses the terminal hosting your Claude session — detected at
  click time by walking the process tree. Works with any macOS terminal.

## What gets installed

| Location | Purpose |
| --- | --- |
| `~/Applications/ClaudeNotifier.app` | Rebranded `terminal-notifier` with the Claude icon. Bundle id `com.keyur.claudenotifier`. |
| `~/.claude/hooks/claude-notify.sh` | The hook script — runs in `stop` and `afk` modes. |
| `~/.claude/settings.json` | One entry added under `hooks.Stop` and `hooks.Notification`. Previous file backed up to `.bak`. |

## Configuration

Sounds are variables at the top of `~/.claude/hooks/claude-notify.sh`:

```bash
STOP_SOUND="Glass"
STOP_ERROR_SOUND="Basso"
AFK_SOUND="Hero"
```

Edit them — the change applies on the next notification, no reload or
re-install. Any file under `/System/Library/Sounds/` works (drop the `.aiff`);
run `ls /System/Library/Sounds/` to list them.

## When to re-run

Re-run `bash ~/.claude/claude-notifier/install.sh` after editing files in
`~/.claude/claude-notifier/`. It is idempotent — re-running migrates older
installs and never duplicates entries.

## Troubleshooting

- **Icon looks generic** — log out and back in once; macOS caches app icons.
- **No notification fires** — System Settings → Notifications → "Claude Notifier"
  → ensure **Allow Notifications** is on. If it is not listed, re-run install.
- **Click does nothing** — restart your Claude session from the terminal directly.
- **Hook never triggers** — check `~/.claude/settings.json` has entries under
  `hooks.Stop` and `hooks.Notification`; re-run install if they are missing.

## Uninstall

```bash
bash ~/.claude/claude-notifier/uninstall.sh
```

Removes the app, hook script, and settings entries. `settings.json.bak` is kept
as a safety net. macOS notification permission stays on — reset it via System
Settings if you want it gone.

## Requirements

- macOS (verified on macOS 26 Tahoe; works on Sonoma+)
- Homebrew — the installer auto-installs `terminal-notifier` and `jq`
- Claude desktop optional — without it the bundled `Claude.icns` fallback is used

## Refreshing the fallback icon

`Claude.icns` is used when Claude desktop is absent. Refresh it from the current
Claude desktop icon:

```bash
bash ~/.claude/claude-notifier/extract-icon.sh
```

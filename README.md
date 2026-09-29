# Claude Notifier

macOS notifications for Claude Code. You get one when a turn ends and one when
Claude needs your input, each with the Claude icon. Clicking a notification
brings back the terminal the session runs in.

## Install

### Let your agent do it

Paste this into Claude Code:

```text
Install Claude Notifier for me: run `brew install keyurgovrani/claude-notifier/claude-notifier`,
then `claude-notifier install`.
The installer sends a "Claude Notifier installed ✓" test notification.
Ask me whether I saw it. If I did not, walk me through
System Settings → Notifications → Claude Notifier to turn on Allow Notifications.
```

### Or do it yourself

With Homebrew:

```bash
brew tap keyurgovrani/claude-notifier
brew install claude-notifier
claude-notifier install
```

Brew cannot write to `~/.claude` or `~/Applications`, so `claude-notifier install`
does the setup after brew puts the files in place.

With git:

```bash
git clone https://github.com/keyurgovrani/homebrew-claude-notifier ~/.claude/claude-notifier
bash ~/.claude/claude-notifier/install.sh
```

With the zip from the latest release:

```bash
curl -fsSL -o /tmp/claude-notifier.zip https://github.com/keyurgovrani/homebrew-claude-notifier/releases/latest/download/claude-notifier.zip
unzip -o /tmp/claude-notifier.zip -d ~/.claude && bash ~/.claude/claude-notifier/install.sh
```

The first time, macOS may ask you to allow notifications from Claude Notifier.
Click **Allow**. If you see neither the prompt nor the test notification, turn
it on in System Settings → Notifications → Claude Notifier.

## What you get

- **Turn-end notification** (`Stop` hook)
  - Title: `Claude · <project>`
  - Subtitle: `<branch>`, or `<branch> ● <N> files` when there are uncommitted changes
  - Message: the last assistant reply, truncated
  - Sound: `Glass`, or `Basso` when the last reply mentions error, failed or blocked
- **Needs-input notification** (`Notification` hook)
  - Title: `Claude needs you · <project>`, plus the tool name for permission prompts
  - Sound: `Hero`, and it shows even in Do Not Disturb
- Clicking either one focuses the terminal hosting your Claude session. It finds
  that terminal when you click, so any macOS terminal works.

## What gets installed

| Location | Purpose |
| --- | --- |
| `~/Applications/ClaudeNotifier.app` | A copy of `terminal-notifier` rebranded with the Claude icon. Bundle id `com.keyur.claudenotifier`. |
| `~/.claude/hooks/claude-notify.sh` | The hook script. It runs in `stop` and `afk` modes. |
| `~/.claude/settings.json` | One entry under `hooks.Stop` and one under `hooks.Notification`. The previous file is kept as `settings.json.bak`. |

## Sounds

The sounds are variables at the top of `~/.claude/hooks/claude-notify.sh`:

```bash
STOP_SOUND="Glass"
STOP_ERROR_SOUND="Basso"
AFK_SOUND="Hero"
```

Edits apply on the next notification with no reinstall. Any file in
`/System/Library/Sounds/` works; drop the `.aiff` from the name.

## Update

```bash
brew upgrade claude-notifier && claude-notifier install
```

For a git install, run `git -C ~/.claude/claude-notifier pull` and then
`bash ~/.claude/claude-notifier/install.sh`.

The installer is safe to re-run. It never duplicates settings entries. It also
replaces `~/.claude/hooks/claude-notify.sh`, so re-apply any sound changes afterwards.

## Troubleshooting

- **Icon looks generic.** Log out and back in once. macOS caches app icons.
- **No notification appears.** Open System Settings → Notifications → Claude
  Notifier and turn on Allow Notifications. If it is not listed, re-run the installer.
- **Turns end about 10 minutes late.** The notifier is stuck waiting on macOS,
  and Claude Code kills the hook at its 10-minute limit. This happens when a second
  copy of `ClaudeNotifier.app` has existed somewhere else on the Mac. Re-run the
  installer to rebuild the app in place.
- **Clicking does nothing.** Start your Claude session directly from the terminal.
- **Hooks never run.** Check that `~/.claude/settings.json` has the entries under
  `hooks.Stop` and `hooks.Notification`, and re-run the installer if they are missing.

## Uninstall

```bash
claude-notifier uninstall && brew uninstall claude-notifier
```

For a git or zip install, run `bash ~/.claude/claude-notifier/uninstall.sh`.

This removes the app, the hook script and the settings entries. It keeps
`settings.json.bak`. The macOS notification permission stays until you reset it
in System Settings.

## Requirements

- macOS, tested on macOS 26 Tahoe
- Homebrew. The installer adds `terminal-notifier` and `jq` when they are missing.
- The Claude desktop app is optional. Without it, the bundled `Claude.icns` supplies the icon.

## Refresh the bundled icon

`Claude.icns` is only used when the Claude desktop app is not installed. To
rebuild it from the current desktop app icon:

```bash
bash ~/.claude/claude-notifier/extract-icon.sh
```

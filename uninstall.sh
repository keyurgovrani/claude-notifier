#!/usr/bin/env bash
# Claude Notifier uninstall — removes everything install.sh installed.
# settings.json.bak is preserved as a safety net; delete it manually once sure.

set -euo pipefail

NOTIFIER_APP="$HOME/Applications/ClaudeNotifier.app"
HOOKS_DIR="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

echo "[claude-notifier] uninstalling..."

rm -rf "$NOTIFIER_APP"
# current hook + pre-rename hooks + the obsolete env file
rm -f "$HOOKS_DIR/claude-notify.sh" "$HOOKS_DIR/stop-notify.sh" "$HOOKS_DIR/notify-afk.sh" "$HOME/.claude/claude-notifier.env"

if [ -f "$SETTINGS" ]; then
  tmp=$(mktemp)
  # remove any Stop/Notification entry referencing our hook (old or new name)
  jq '
    def strip($re):
      map(select((.hooks // []) | map(.command // "" | test($re)) | any | not));
    .hooks //= {}
    | .hooks.Stop         |= (. // [] | strip("stop-notify\\.sh|claude-notify\\.sh"))
    | .hooks.Notification |= (. // [] | strip("notify-afk\\.sh|claude-notify\\.sh"))
  ' "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
fi

"$LSREGISTER" -u "$NOTIFIER_APP" 2>/dev/null || true
killall Dock Finder NotificationCenter usernoted 2>/dev/null || true

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  ORANGE=$'\e[38;2;217;119;6m'; BOLD=$'\e[1m'; DIM=$'\e[2m'; RESET=$'\e[0m'
else
  ORANGE=""; BOLD=""; DIM=""; RESET=""
fi

cat <<SUMMARY

${ORANGE}${BOLD}✦ Claude Notifier uninstalled.${RESET}

${DIM}Backup preserved (delete when you're sure you won't revert):${RESET}
  ${ORANGE}•${RESET} ~/.claude/settings.json.bak

${DIM}macOS notification permission for 'com.keyur.claudenotifier' stays on —${RESET}
${DIM}reset it via System Settings → Notifications → Claude Notifier if you want it gone.${RESET}

SUMMARY

#!/usr/bin/env bash
# Claude Notifier install — builds the notifier app, installs the hook, merges
# settings.json. Idempotent: safe to re-run after pulling hook updates.
# Migrates pre-rename installs (stop-notify.sh / notify-afk.sh / env file).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFIER_APP="$HOME/Applications/ClaudeNotifier.app"
HOOKS_DIR="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"
HOOK_DEST="$HOOKS_DIR/claude-notify.sh"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

trap 'echo "[claude-notifier] install failed at: $BASH_COMMAND — restore $SETTINGS.bak if settings.json looks wrong." >&2' ERR

CLAUDE_APP_PRESENT=0

preflight() {
  [[ "$OSTYPE" == darwin* ]] || { echo "error: macOS only (detected $OSTYPE)." >&2; exit 1; }
  command -v brew >/dev/null 2>&1 || { echo "error: Homebrew not found — install from https://brew.sh first." >&2; exit 1; }
  if ! command -v jq >/dev/null 2>&1; then
    echo "  installing jq..."
    brew install jq
  fi
  if [ -d "/Applications/Claude.app" ]; then CLAUDE_APP_PRESENT=1; fi
}

build_app() {
  if ! brew list terminal-notifier >/dev/null 2>&1; then
    echo "  installing terminal-notifier..."
    brew install terminal-notifier
  fi
  local src_app
  src_app="$(brew --prefix terminal-notifier)/terminal-notifier.app"
  [ -d "$src_app" ] || { echo "error: terminal-notifier.app not found at $src_app" >&2; exit 1; }

  mkdir -p "$HOME/Applications"
  rm -rf "$NOTIFIER_APP"
  cp -R "$src_app" "$NOTIFIER_APP"

  # icon: Claude desktop's Assets.car if present, else the bundled .icns fallback
  local icon_key icon_value
  if [ "$CLAUDE_APP_PRESENT" = "1" ]; then
    cp "/Applications/Claude.app/Contents/Resources/Assets.car" "$NOTIFIER_APP/Contents/Resources/Assets.car"
    icon_key="CFBundleIconName"; icon_value="Claude"
  else
    cp "$SCRIPT_DIR/Claude.icns" "$NOTIFIER_APP/Contents/Resources/Claude.icns"
    icon_key="CFBundleIconFile"; icon_value="Claude"
  fi
  rm -f "$NOTIFIER_APP/Contents/Resources/Terminal.icns"

  local plist="$NOTIFIER_APP/Contents/Info.plist"
  plutil -replace CFBundleIdentifier  -string "com.keyur.claudenotifier" "$plist"
  plutil -replace CFBundleName        -string "Claude Notifier" "$plist"
  plutil -replace CFBundleDisplayName -string "Claude Notifier" "$plist"
  plutil -remove  CFBundleIconFile "$plist" 2>/dev/null || true
  plutil -remove  CFBundleIconName "$plist" 2>/dev/null || true
  plutil -insert  "$icon_key" -string "$icon_value" "$plist"
  plutil -replace CFBundleVersion -string "$(date +%s)" "$plist"

  codesign --force --deep --sign - "$NOTIFIER_APP" >/dev/null
}

install_hook() {
  mkdir -p "$HOOKS_DIR"
  cp "$SCRIPT_DIR/claude-notify.sh" "$HOOK_DEST"
  chmod +x "$HOOK_DEST"
  # migration: drop pre-rename hooks + the obsolete env file
  rm -f "$HOOKS_DIR/stop-notify.sh" "$HOOKS_DIR/notify-afk.sh" "$HOME/.claude/claude-notifier.env"
}

merge_settings() {
  if [ ! -f "$SETTINGS" ]; then
    mkdir -p "$(dirname "$SETTINGS")"
    echo '{"hooks":{}}' > "$SETTINGS"
  fi
  cp "$SETTINGS" "$SETTINGS.bak"

  # strip-then-append: remove any Stop/Notification entry referencing an old or
  # new script name, then append one fresh entry each. Idempotent, and absorbs
  # the stop-notify.sh / notify-afk.sh -> claude-notify.sh rename.
  local tmp
  tmp=$(mktemp)
  jq \
    --arg stopCmd "bash ~/.claude/hooks/claude-notify.sh stop" \
    --arg notifCmd "bash ~/.claude/hooks/claude-notify.sh afk" '
    def strip($re):
      map(select((.hooks // []) | map(.command // "" | test($re)) | any | not));
    .hooks //= {}
    | .hooks.Stop |= (
        (. // []) | strip("stop-notify\\.sh|claude-notify\\.sh")
        + [{ matcher: "", hooks: [{ type: "command", command: $stopCmd }] }]
      )
    | .hooks.Notification |= (
        (. // []) | strip("notify-afk\\.sh|claude-notify\\.sh")
        + [{ matcher: "", hooks: [{ type: "command", command: $notifCmd }] }]
      )
  ' "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
}

test_notification() {
  "$NOTIFIER_APP/Contents/MacOS/terminal-notifier" \
    -title "Claude Notifier installed ✓" \
    -message "If you don't see this, enable Claude Notifier in System Settings → Notifications." \
    -sound Glass >/dev/null 2>&1 || true
}

summary() {
  local orange="" bold="" dim="" reset=""
  if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    orange=$'\e[38;2;217;119;6m'; bold=$'\e[1m'; dim=$'\e[2m'; reset=$'\e[0m'
  fi
  cat <<SUMMARY

${orange}${bold}✦ Claude Notifier installed.${reset}

  ${orange}•${reset} App:      ~/Applications/ClaudeNotifier.app
  ${orange}•${reset} Hook:     ~/.claude/hooks/claude-notify.sh ${dim}(edit the SOUND vars to change sounds)${reset}
  ${orange}•${reset} Settings: ~/.claude/settings.json updated ${dim}(backup at .bak)${reset}

${dim}Re-run ${bold}bash ~/.claude/claude-notifier/install.sh${reset}${dim} after editing files in ~/.claude/claude-notifier/.${reset}

SUMMARY
}

main() {
  echo "[claude-notifier] installing..."
  preflight

  # icon-cache flush only matters when rebuilding over an existing .app
  local app_preexisted=0
  [ -d "$NOTIFIER_APP" ] && app_preexisted=1

  build_app
  "$LSREGISTER" -f "$NOTIFIER_APP"
  if [ "$app_preexisted" = "1" ]; then
    killall Dock Finder NotificationCenter usernoted 2>/dev/null || true
  fi

  install_hook
  merge_settings
  test_notification
  summary
}

main "$@"

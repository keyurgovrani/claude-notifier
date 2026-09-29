#!/usr/bin/env bash
# Claude Code notification hook — fired by both the Stop and Notification events.
# Mode is the first argument:
#   stop  turn-end ping     — project title, git branch + dirty count, last reply
#   afk   needs-input ping  — louder sound, DnD bypass, tool name from the prompt
# Edit the SOUND vars below to change sounds — applies on the next fire.
# Click-focus uses -execute, not -activate: macOS 26 neutered -activate's click
# handler (and -group's delivery). -execute runs a shell command on click.

STOP_SOUND="Glass"
STOP_ERROR_SOUND="Basso"
AFK_SOUND="Hero"

mode="${1:-}"

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // empty')

proj="Claude"
[ -n "$cwd" ] && proj=$(basename "$cwd")

NOTIFIER="$HOME/Applications/ClaudeNotifier.app/Contents/MacOS/terminal-notifier"
[ ! -x "$NOTIFIER" ] && NOTIFIER="$(command -v terminal-notifier)"

# click-focus: the topmost ancestor whose parent is launchd (pid 1) is the UI
# app hosting this session. Embed its pid in an AppleScript focus-by-id payload.
activate_args=()
walk_pid=$$
while [ "$walk_pid" -gt 1 ]; do
  walk_parent=$(ps -o ppid= -p "$walk_pid" 2>/dev/null | tr -d ' ')
  [ -z "$walk_parent" ] && break
  [ "$walk_parent" = "1" ] && break
  walk_pid="$walk_parent"
done
if [ "$walk_pid" -gt 1 ]; then
  activate_args=(-execute "osascript -e 'tell application \"System Events\" to set frontmost of (first process whose unix id is $walk_pid) to true'")
fi

case "$mode" in
  stop)
    transcript=$(echo "$input" | jq -r '.transcript_path // empty')

    # subtitle: "main" clean, "main ● 3 files" with uncommitted changes
    branch="-"
    if { [ -n "$cwd" ] && [ -d "$cwd/.git" ]; } || git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "-")
      dirty_count=$(git -C "$cwd" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      if [ -n "$dirty_count" ] && [ "$dirty_count" -gt 0 ] 2>/dev/null; then
        if [ "$dirty_count" = "1" ]; then
          branch="$branch ● 1 file"
        else
          branch="$branch ● $dirty_count files"
        fi
      fi
    fi

    # last assistant text — reverse the transcript, take first text block, truncate
    last=""
    if [ -n "$transcript" ] && [ -f "$transcript" ]; then
      last=$(tail -r "$transcript" 2>/dev/null \
        | jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' 2>/dev/null \
        | head -n 1 \
        | tr '\n' ' ' \
        | cut -c1-140)
    fi
    [ -z "$last" ] && last="Finished"

    sound="$STOP_SOUND"
    echo "$last" | grep -qiE "error|failed|cannot|blocked|denied" && sound="$STOP_ERROR_SOUND"

    "$NOTIFIER" \
      -title "Claude · $proj" \
      -subtitle "$branch" \
      -message "$last" \
      -sound "$sound" \
      "${activate_args[@]}" \
      >/dev/null 2>&1 || true
    ;;

  afk)
    message=$(echo "$input" | jq -r '.message // "Needs input"')
    msg_short=$(echo "$message" | tr '\n' ' ' | cut -c1-160)

    # tool name from "permission to use/run/execute <Tool>" — shown in the title
    tool=$(echo "$message" | sed -nE 's/.*[Pp]ermission to (use|run|execute) ([A-Za-z_][A-Za-z0-9_-]*).*/\2/p' | head -1)
    title_suffix=""
    [ -n "$tool" ] && title_suffix=" · $tool"

    "$NOTIFIER" \
      -title "Claude needs you · $proj$title_suffix" \
      -message "$msg_short" \
      -sound "$AFK_SOUND" \
      -ignoreDnD \
      "${activate_args[@]}" \
      >/dev/null 2>&1 || true
    ;;

  *)
    echo "claude-notify: unknown mode '${mode}' (expected 'stop' or 'afk')" >&2
    exit 0
    ;;
esac

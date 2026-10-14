#!/bin/bash
# Shared nest helpers (~/agent-spaces, see its README), sourced by diary-context.sh
# (SessionStart) and nest-mention.sh (UserPromptSubmit). bash 3.2 safe.
spaces="${AGENT_SPACES:-$HOME/agent-spaces}"

nest_exists() { [ -n "$1" ] && [ -f "$spaces/$1/README.md" ]; }

# nest_mark <sid8> <nest>: remember which agent this session is.
nest_mark() {
  mkdir -p "$spaces/.sessions"
  printf '%s\n' "$2" > "$spaces/.sessions/$1"
}

# nest_marked <sid8>: the agent this session already is, if any.
nest_marked() {
  [ -f "$spaces/.sessions/$1" ] && head -1 "$spaces/.sessions/$1"
}

# First paragraph of a nest README, on one line.
nest_blurb() {
  awk '/^#/ {if (p) exit; next} NF {p=1; printf "%s ", $0; next} p {exit}' "$1/README.md" | cut -c1-300
}

# nest_title <nest>: the agent's display name (lathe -> Lathe).
nest_title() {
  printf '%s' "$(printf '%s' "${1:0:1}" | tr '[:lower:]' '[:upper:]')${1:1}"
}

# nest_context <nest> <sid8>: the wake-up context for a named agent.
nest_context() {
  local nest=$1 sid=$2 home Name latest
  home="$spaces/$nest"
  Name=$(nest_title "$nest")
  latest=$(ls "$home/diary" 2>/dev/null | grep '\.md$' | sort | tail -1)
  printf '%s' "Session name for the diary: $sid. This session is $Name, a named agent whose home is $home (layout in $spaces/README.md). Your diary for today goes to $home/diary/$(date +%F).md, not ~/.claude/diaries. Other sessions of this agent share that day's file: append your own section and never rewrite theirs. Before the session ends, also rewrite handoff.md, put job lessons in notes/, and commit ~/agent-spaces. Other sessions of $Name may be open, so once you know the task, title this session \"$Name · <the task in two to four words>\" (for example \"$Name · roster wording\") with mcp__ccd_session_mgmt__set_session_title (session_id \"self\"), and retitle it if the task changes."
  printf '\n\n--- %s ---\n%s' "$home/README.md" "$(cat "$home/README.md")"
  printf '\n\n--- %s ---\n%s' "$home/handoff.md" "$(cat "$home/handoff.md" 2>/dev/null)"
  if [ -n "$latest" ]; then
    printf '\n\n--- %s ---\n%s' "$home/diary/$latest" "$(cat "$home/diary/$latest")"
  fi
}

#!/bin/bash
# SessionStart hook: gives Claude this session's name for the diary rule in
# ~/.claude/CLAUDE.md, and after a compaction asks for the entry.
# Subagents (Agent tool, workflow agents) also run this hook, with the parent's
# session_id. They get no diary instruction: after a compaction they are told to
# check the real state instead (decided 2026-10-14, see ~/.claude/token-management.md).
#
# Nests (~/agent-spaces, see its README): a main session that belongs to a named agent
# gets that agent's README, hand-off and latest diary. The agent is found from
# AGENT_NEST (set by ~/.local/bin/agent), the session marker .sessions/<id8> (written
# here, by nest-mention.sh when a message starts with "@name", or by the nest skill), or
# on startup a pick made in the last 15 minutes with `agent next <name>` (.next, used once).
# Sessions with no agent get a short roster so Claude can take on a matching one.
. "$(dirname "$0")/nest-lib.sh"
input=$(cat)
sid=$(jq -r '.session_id // "unknown"' <<<"$input" | cut -c1-8)
src=$(jq -r '.source // empty' <<<"$input")
agent_id=$(jq -r '.agent_id // empty' <<<"$input")
tpath=$(jq -r '.transcript_path // empty' <<<"$input")

subagent=""
if [ -n "$agent_id" ] || [[ "$tpath" == */subagents/* ]]; then
  subagent=1
fi

# Evidence log: field names only, never values, so we can confirm how subagents are detected.
if [ "$src" = "compact" ]; then
  printf '%s source=%s subagent=%s keys=%s\n' "$(date '+%F %T')" "$src" "${subagent:-0}" \
    "$(jq -c 'keys' <<<"$input")" >> "$HOME/.claude/hooks/diary-context.log"
fi

nest=""
fresh=""  # a brand-new session started as an agent: it speaks first
if [ -z "$subagent" ] && [ -d "$spaces" ]; then
  if [ -n "${AGENT_NEST:-}" ]; then
    nest="$AGENT_NEST"
    [ "$src" = "startup" ] && fresh=1
  elif [ -f "$spaces/.sessions/$sid" ]; then
    nest=$(nest_marked "$sid")
  elif [ "$src" = "startup" ] && [ -n "$(find "$spaces/.next" -mmin -15 2>/dev/null)" ]; then
    nest=$(head -1 "$spaces/.next")
    rm -f "$spaces/.next"
    fresh=1
  fi
  nest_exists "$nest" || nest=""
  [ -n "$nest" ] && nest_mark "$sid" "$nest"
fi

if [ -n "$subagent" ]; then
  if [ "$src" = "compact" ]; then
    msg="A compaction just happened. Before continuing, check the real state against the summary above (git status, git log -5, the last check or test result) and fix any mismatch in your understanding. Subagents do not write diaries; put lessons in your final report."
  else
    exit 0
  fi
elif [ -n "$nest" ]; then
  msg=$(nest_context "$nest" "$sid")
  if [ "$src" = "compact" ]; then
    msg="A compaction just happened: write the diary entry for the work in the summary above before continuing.

$msg"
  fi
else
  # Project = the main checkout's folder name, so worktree sessions file under their repo.
  cwd=$(jq -r '.cwd // empty' <<<"$input")
  [ -n "$cwd" ] || cwd="$PWD"
  common=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  if [ -n "$common" ]; then
    project=$(basename "$(dirname "$common")")
  else
    project=$(basename "$cwd")
  fi
  msg="Session name for the diary: $sid. Diary path: ~/.claude/diaries/$project/$sid/$(date +%F).md"
  if [ "$src" = "compact" ]; then
    msg="$msg. A compaction just happened: write the diary entry for the work in the summary above before continuing."
  fi
  roster=""
  for d in "$spaces"/*/; do
    [ -f "$d/README.md" ] || continue
    roster="$roster
- $(basename "$d"): $(nest_blurb "${d%/}")"
  done
  if [ -n "$roster" ]; then
    msg="$msg

Named agents live in $spaces:$roster
A message starting with \"@name\" loads that agent by itself. Otherwise, if the user's first request clearly falls within one agent's job, become that agent: follow the nest skill's load steps (marker, README, hand-off, latest diary, session title) and say so in one line. If nothing fits, ignore this list."
  fi
fi
title=""; first=""
if [ -n "$nest" ]; then
  title=$(nest_title "$nest")
  [ -n "$fresh" ] && first="Restate where your hand-off says things stand and what you'll do next, in two or three lines."
fi
jq -n --arg m "$msg" --arg t "$title" --arg f "$first" \
  '{hookSpecificOutput:({hookEventName:"SessionStart",additionalContext:$m}
    + (if $t != "" then {sessionTitle:$t} else {} end)
    + (if $f != "" then {initialUserMessage:$f} else {} end))}'

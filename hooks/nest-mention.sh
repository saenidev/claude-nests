#!/bin/bash
# UserPromptSubmit hook: a message that starts with an agent's name ("@lathe ..." or
# "lathe: ...") makes this session that agent (a nest in ~/agent-spaces). Loads its
# README, hand-off and latest diary and marks the session so the SessionStart hook
# reloads it on resume, /clear and after a compaction. Silent otherwise.
. "$(dirname "$0")/nest-lib.sh"
input=$(cat)
sid=$(jq -r '.session_id // "unknown"' <<<"$input" | cut -c1-8)
first=$(jq -r '.prompt // empty' <<<"$input" | awk 'NF {print $1; exit}' | tr '[:upper:]' '[:lower:]')

name=""
if [[ "$first" =~ ^@([a-z0-9_-]+)[,:]?$ ]]; then
  name="${BASH_REMATCH[1]}"
elif [[ "$first" =~ ^([a-z0-9_-]+):$ ]]; then
  name="${BASH_REMATCH[1]}"
fi
nest_exists "$name" || exit 0
[ "$(nest_marked "$sid")" = "$name" ] && exit 0

nest_mark "$sid" "$name"
msg="The user called this session by an agent's name, so become that agent now and say so in one line.

$(nest_context "$name" "$sid")"
jq -n --arg m "$msg" --arg t "$(nest_title "$name")" \
  '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$m,sessionTitle:$t}}'

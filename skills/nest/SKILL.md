---
name: nest
description: Load a named agent's nest from ~/agent-spaces/ (its identity, hand-off and latest diary) or make a new one. Use when Jun types /nest <name>, /nest new, "wake <name>", or asks to start a session as a named agent.
---

# Nest

A nest is `~/agent-spaces/<name>/`. Read `~/agent-spaces/README.md` if you need the layout.

Usually no command is needed: a message starting with `@<name>` loads the nest (hook
`nest-mention.sh`), and the SessionStart hook loads it for `agent <name>` (terminal),
`agent next <name>` (the next new session, desktop or terminal) and resumed sessions, and lists
the agents otherwise so you can take on one whose job matches the first request. Then follow
the load steps below.

## `/nest <name>`: load a nest

1. Check `~/agent-spaces/<name>/` exists. If not, list the nests and stop.
2. Take this session's id from the SessionStart context line "Session name for the diary: <id>"
   and write the marker: `printf '%s\n' <name> > ~/agent-spaces/.sessions/<id>`. The diary hook
   reads it to reload the nest on resume, `/clear` and after a compaction.
3. Read `README.md`, `handoff.md` and the newest file in `diary/`, unless the SessionStart
   context already holds them (the hook loads a nest it knows about by itself).
4. In the desktop app, once you know the task, title the session `<Name> · <the task in two to
   four words>` with `mcp__ccd_session_mgmt__set_session_title` (`session_id: "self"`), so it stands
   apart from other sessions of the same agent.
5. Reply in two or three lines: who you are, where the hand-off says things stand, and what you
   will do next (or ask Jun what's next if the hand-off has no open item).

## `/nest new`: make a new agent

1. Ask Jun what the agent's job is if they haven't said.
2. Pick your own name and tell Jun why you chose it. Use a short lowercase word for the folder.
3. Write `README.md` in your own words: who you are, your job, how you got your name, the skills
   the job uses. Symlink those skills into `skills/` (`ln -s ~/.claude/skills/<skill> skills/`).
4. Create an empty `handoff.md`, plus `diary/` and `notes/`. Write the session marker as above.

## Before the session ends

- Write today's diary entry in `~/agent-spaces/<name>/diary/<YYYY-MM-DD>.md`, not in
  `~/.claude/diaries/`. Same style as the global diary rule: first-person prose.
- Rewrite `handoff.md` so it holds only the present: where things stand and what's next.
- Put lessons about the job in `notes/`. A lesson another agent needs goes into a rule, a skill
  or the project's docs instead.
- Commit: `git -C ~/agent-spaces add -A && git -C ~/agent-spaces commit -m "<name>: <what changed>"`.

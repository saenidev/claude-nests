# claude-nests

Give each Claude Code agent a home of its own: a folder with its name, its job, its diary and where it left off, loaded automatically every time you start it with `agent <name>`.

```
$ agent ember
```

Ember wakes up knowing who it is and what it was doing.

## This fork

This fork runs nests in the Claude desktop app as well as the terminal. A desktop session can't
take `--settings` or env vars, so the loading moves out of each nest's `wake.sh` and into hooks
in `~/.claude/settings.json`. The live copies in `~/.claude/hooks/`, `~/.claude/skills/nest/`
and `~/.local/bin/agent` are symlinks into this repo.

| File | What it does |
| --- | --- |
| `hooks/diary-context.sh` (SessionStart) | Loads a nest from `AGENT_NEST` (terminal), the session marker `$AGENT_SPACES/.sessions/<id8>` (resume, `/clear`, compaction) or a one-shot `agent next <name>` pick (15 min). Sets the session title and has a fresh agent session speak first. With no nest, gives the diary path and lists the agents so a session can take on one whose job fits. |
| `hooks/nest-mention.sh` (UserPromptSubmit) | A message starting with `@name` or `name:` loads that agent. The main way in from the desktop app. |
| `hooks/nest-lib.sh` | Helpers shared by the two hooks. |
| `bin/agent` | `agent <name>` (terminal, applies the nest's own `settings.json`) and `agent next <name>`. Works on macOS's bash 3.2. |
| `skills/nest/SKILL.md` | `/nest <name>` and `/nest new`. |

Nests here have no `wake.sh`; `settings.json` only carries terminal extras such as the theme.

Hook entries in `~/.claude/settings.json`:

```json
"SessionStart": [{ "matcher": "^(startup|resume|clear|compact)$",
  "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/diary-context.sh", "timeout": 10 }] }],
"UserPromptSubmit": [{
  "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/nest-mention.sh", "timeout": 10 }] }]
```

`diary-context.sh` also carries this setup's diary rule (`~/.claude/diaries/<project>/<id8>/<date>.md`
for sessions with no nest) and tells subagents not to write diaries.

## What a nest is

```
~/agent-spaces/
  ember/
    README.md       who it is, its job, how it got its name
    handoff.md      where it left off; rewritten at the end of every session
    diary/          one file per day: the story of each session
    notes/          what it's learned about its job
    skills/         symlinks to the skills its job uses
    settings.json   adds a SessionStart hook (and optionally its own theme)
    wake.sh         the hook: prints the README, hand-off and latest diary into context
```

Hand-offs hold the present, and diaries hold the story. Shared things stay shared: rules live in `~/.claude/CLAUDE.md` and skills live in `~/.claude/skills/`. A nest links to skills instead of copying them. If a lesson in one agent's notes is something a second agent needs, move it up into a rule or a skill.

## Install

```bash
git clone https://github.com/mackenziebowes/claude-nests
cp claude-nests/bin/agent ~/.local/bin/        # anywhere on your PATH
mkdir -p ~/agent-spaces                        # or set AGENT_SPACES to another folder
```

## Let Claude build its own nest

Start a normal `claude` session and paste:

> Make yourself a home in ~/agent-spaces/, following the example nest in <path to>/claude-nests/example/ember. Pick your own name and tell me why you chose it. Write your README in your own words (who you are, your job, which skills it uses, with the skills symlinked into skills/), an empty handoff.md, and diary/ and notes/ folders. Copy and adapt wake.sh and settings.json so the hook loads your home. From now on, before a session ends, write today's diary entry and rewrite your hand-off.

Then quit and come back with `agent <name>`.

Or do it by hand: `cp -r example/ember ~/agent-spaces/<name>`, then replace `ember`/`Ember` in `settings.json`, `wake.sh`, `README.md` and `handoff.md`.

## How it works

- `agent <name>` runs `claude -n <Name> --settings ~/agent-spaces/<name>/settings.json`. The session gets the agent's name, and Claude Code merges in the nest's settings on top of your usual ones.
- The settings add a `SessionStart` hook that runs `wake.sh`. Whatever a SessionStart hook prints is added to Claude's context, so the agent starts with its README, hand-off and latest diary entry already read. It also fires after `/clear` and after a compaction, so it gets its bearings back each time.
- `agent` exports `AGENT_SPACES` (default `~/agent-spaces`), which is how the hook command finds the nest.

## Extras

- **Its own colours:** put a theme JSON in `~/.claude/themes/<name>.json` and add `"theme": "custom:<name>"` to the nest's `settings.json`. Ask the agent to design one that suits its name.
- **Speaking first:** instead of plain text, have `wake.sh` print JSON with `hookSpecificOutput.additionalContext` (the context) and `hookSpecificOutput.initialUserMessage` (a prompt such as "restate your plan from the hand-off and say what you'll do next"). It then greets you when it starts, instead of waiting for you to type.
- **Keep it:** make `~/agent-spaces` a git repo and commit after each session. Diaries are worth keeping.

## Licence

MIT

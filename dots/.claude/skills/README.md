# Claude Code Skills

Global skills directory, symlinked from dotfiles to `~/.claude/skills/`. Skills here are available across all projects.

## Writing your own skill

Create a folder with a `SKILL.md` file:

```
my-skill/
├── SKILL.md           # required: frontmatter + instructions
├── references/        # optional: extra docs the skill can read
└── scripts/           # optional: helper scripts
```

**SKILL.md format:**

```yaml
---
name: my-skill
description: What it does (Claude uses this to decide when to auto-activate)
# disable-model-invocation: true   # set to only allow manual /my-skill invocation
# allowed-tools: Read, Grep, Bash  # tools allowed without asking permission
# context: fork                    # run in isolated subagent
---

Instructions for Claude when this skill is invoked.
Use $ARGUMENTS to access user input.
```

Invoke with `/my-skill` in Claude Code. Skills with a `description` also auto-activate when Claude detects a matching task.

## Notes

- Skills here are **personal** (all projects). For project-specific skills, use `.claude/skills/` inside the repo.
- Skills installed via **plugins** (`claude plugins install ...`) are separate — managed in `~/.claude/plugins/` with their own versioning and updates. See `config/claude/setup.sh` for the list of installed plugins.
- Type `/` in Claude Code to see all available skills (both from here and from plugins).

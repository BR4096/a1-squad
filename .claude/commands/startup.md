---
description: Initialize session with context review and environment check
---

Run the session startup script, then review key project state.

## Step 1: Run environment checks

```bash
./scripts/session-startup.sh
```

## Step 2: Read project state

Read these files and summarize their status:

1. **PROJECT-STATE.md** -- current sprint, known issues, next actions
2. **DEVLOG.md** -- WIP section for incomplete tasks
3. **BACKLOG.md** -- prioritized backlog

## Step 3: Report and recommend

Provide a concise session briefing:
- Environment health (pass/fail from the script output)
- Uncommitted changes or stashed work (if any)
- Reference image library status (how many of 20 minimum)
- Top 3 recommended actions for this session based on BACKLOG.md priorities and WIP items

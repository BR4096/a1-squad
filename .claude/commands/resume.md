# Session Resume Command

You are starting a new session. Follow this protocol:

## Step 1: Load Context

Read these files to understand current state:
1. `CLAUDE.md` - Project context and guidelines
2. `DEVLOG.md` - Check "Work In Progress" section for incomplete tasks
3. `PROJECT-STATE.md` - Current project health
4. `BACKLOG.md` - Prioritized task list

## Step 2: Check Environment

```bash
# Verify venv
.venv/bin/python3 -c "import google.genai; print('SDK OK')"

# Git state
git status --short
git stash list
git log --oneline -5
```

## Step 3: Report Status

After reading the context files, report:
- Any incomplete work found in DEVLOG.md
- Current project health from PROJECT-STATE.md
- Current git branch and uncommitted changes
- Recommended next steps from BACKLOG.md

## Context Rules

1. Do NOT re-read code from completed phases unless needed for imports
2. Focus only on files required for current work
3. Trust that documented completed work functions as specified

## Response Format

```
## Session Resume Report

**Git Branch**: [branch name]
**Uncommitted Changes**: [count or "clean"]
**API Status**: [OK or issue]

### Work In Progress
[Summary from DEVLOG.md or "None found"]

### Recommended Next Steps
1. [First priority from BACKLOG.md]
2. [Second priority]
```

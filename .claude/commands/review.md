---
description: Review recent changes following code review protocol
---

# Code Review Command

Review all uncommitted changes and recent commits.

## Process

1. Run `git diff` to see all unstaged changes
2. Run `git diff --staged` to see staged changes
3. Run `git log --oneline -10` to see recent commits
4. For each changed file, check:
   - Security: no hardcoded API keys or secrets in code
   - API usage: correct model name, uppercase K resolution, narrative prompts
   - Error handling: proper try/except, no bare `except:`
   - File handling: outputs saved to `outputs/`, no overwrites
   - Patterns: follows project conventions from CLAUDE.md

## Output Format

```
## Code Review Report

### Summary
[X files changed, Y insertions, Z deletions]

### Issues Found
- **[severity]** file:line - description

### Recommendations
- suggestion 1
- suggestion 2

### Verdict
[PASS / PASS WITH NOTES / NEEDS CHANGES]
```

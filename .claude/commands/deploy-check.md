---
description: Pre-deployment verification checklist
---

# Deploy Check Command

Run pre-deployment verification.

## Checks

1. **Lint**: Run ruff check
2. **Format**: Run ruff format check
3. **Tests**: Run pytest
4. **API**: Verify Gemini API connectivity
5. **Git Status**: Verify no uncommitted changes
6. **Secrets**: Verify .env is gitignored and no keys in code

## Execution

```bash
# Lint and format
.venv/bin/python3 -m ruff check . 2>&1 || echo "ruff not installed"
.venv/bin/python3 -m ruff format --check . 2>&1 || echo "ruff not installed"

# Tests
.venv/bin/python3 -m pytest 2>&1 || echo "No tests configured"

# Git
git status --short
git log --oneline -5
```

## Output Format

```
## Deploy Check Report

| Check | Status | Notes |
|-------|--------|-------|
| Lint | PASS/FAIL/N/A | |
| Format | PASS/FAIL/N/A | |
| Tests | PASS/FAIL/N/A | X/Y passing |
| API | PASS/FAIL | |
| Git Clean | PASS/FAIL | |
| Secrets Safe | PASS/FAIL | |

### Verdict
[READY / NOT READY - fix issues above]
```

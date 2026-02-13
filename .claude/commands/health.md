---
description: Quick project health assessment
---

# Health Check Command

Run a quick project health assessment.

## Checks

1. **File counts**: Scripts, tests, reference images, generated outputs
2. **Dependencies**: Verify all packages installed in venv
3. **Documentation**: CLAUDE.md, DEVLOG.md, CHANGELOG.md, PROJECT-STATE.md presence and recency
4. **Git health**: Uncommitted changes, branch status

## Execution

```bash
# File inventory
echo "Python scripts:" && find . -name "*.py" -not -path "./.venv/*" | wc -l
echo "Tests:" && find . -name "test_*.py" -not -path "./.venv/*" | wc -l
echo "Reference images:" && find reference-images -type f -not -name ".DS_Store" 2>/dev/null | wc -l
echo "Generated outputs:" && find outputs -type f -not -name ".DS_Store" 2>/dev/null | wc -l

# Dependencies
.venv/bin/pip list --format=columns 2>/dev/null | grep -E "google-genai|Pillow|python-dotenv"

# Git
git status --short | wc -l
git log --oneline -1
```

## Output Format

```
## Project Health Report

### Inventory
| Type | Count |
|------|-------|
| Python scripts | X |
| Tests | X |
| Reference images | X |
| Generated outputs | X |

### Dependencies
| Package | Version | Status |
|---------|---------|--------|
| google-genai | X.X.X | OK |
| Pillow | X.X.X | OK |
| python-dotenv | X.X.X | OK |

### Documentation
| Doc | Present | Last Updated |
|-----|---------|-------------|
| CLAUDE.md | Yes/No | date |
| DEVLOG.md | Yes/No | date |
| CHANGELOG.md | Yes/No | date |
| PROJECT-STATE.md | Yes/No | date |
```

#!/bin/bash
# Session startup for Banana Squad (Python project)
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "========================================"
echo "   BANANA SQUAD - SESSION STARTUP"
echo "========================================"
echo ""
echo "Time: $(date)"
echo ""

# Phase 1: Context Recovery
echo "--- Phase 1: Context Recovery ---"

LAST_SESSION=$(ls -t docs/session-notes/*.md 2>/dev/null | head -1)
if [ -n "$LAST_SESSION" ]; then
  echo "Last session: $(basename "$LAST_SESSION")"
else
  echo "No previous session notes found"
fi

echo ""
echo "Git Status:"
git status --short 2>/dev/null || echo "  (not a git repo)"

STASH_COUNT=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
if [ "$STASH_COUNT" -gt 0 ]; then
  echo "WARNING: $STASH_COUNT stashed change(s) found"
fi

echo ""
echo "Recent Commits:"
git log --oneline -5 2>/dev/null || echo "  (no commits)"

# Phase 2: Environment Verification
echo ""
echo "--- Phase 2: Environment ---"

echo "Python: $(python3 --version 2>/dev/null || echo 'not found')"

if [ -d ".venv" ]; then
  echo "Venv: .venv/ exists"

  # Check key deps
  .venv/bin/python3 -c "import google.genai; print('google-genai: OK')" 2>/dev/null || echo "google-genai: MISSING"
  .venv/bin/python3 -c "from PIL import Image; print('Pillow: OK')" 2>/dev/null || echo "Pillow: MISSING"
  .venv/bin/python3 -c "import dotenv; print('python-dotenv: OK')" 2>/dev/null || echo "python-dotenv: MISSING"
else
  echo "WARNING: No .venv/ found. Run: python3 -m venv .venv && .venv/bin/pip install google-genai Pillow python-dotenv"
fi

# Check API key
if [ -f ".env" ]; then
  if grep -q "GEMINI_API_KEY" .env 2>/dev/null; then
    echo "API Key: configured in .env"
  else
    echo "WARNING: GEMINI_API_KEY not found in .env"
  fi
else
  echo "WARNING: No .env file. Copy .env.example to .env and add your key."
fi

# Phase 3: Documentation State
echo ""
echo "--- Phase 3: Documentation ---"

for doc in CLAUDE.md DEVLOG.md CHANGELOG.md PROJECT-STATE.md AGENTS.md BACKLOG.md; do
  if [ -f "$doc" ]; then
    MOD_DATE=$(stat -f "%Sm" -t "%Y-%m-%d" "$doc" 2>/dev/null || stat -c "%y" "$doc" 2>/dev/null | cut -d' ' -f1)
    echo "  $doc ($MOD_DATE)"
  else
    echo "  $doc (not found)"
  fi
done

# Phase 4: Ready
echo ""
echo "========================================"
echo "Session initialized!"
echo ""
echo "Next steps:"
echo "  1. Review DEVLOG.md WIP section"
echo "  2. Check BACKLOG.md for priorities"
echo "  3. Define session goals"
echo "========================================"

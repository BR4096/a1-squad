---
description: Initialize session with context review and environment check
---

Run the session startup to:

1. Read PROJECT-STATE.md for current project health
2. Read DEVLOG.md WIP section for incomplete tasks
3. Check git status for uncommitted changes or stashed work
4. Verify Python venv and dependencies are intact
5. Verify Gemini API key is configured in .env
6. Generate a prioritized task list from BACKLOG.md

Execute:
```bash
# Verify environment
source .venv/bin/activate
python3 -c "from google import genai; print('google-genai OK')"
python3 -c "from PIL import Image; print('Pillow OK')"
python3 -c "from dotenv import load_dotenv; load_dotenv(); import os; print('API key:', 'SET' if os.getenv('GEMINI_API_KEY') else 'MISSING')"

# Git state
git status --short
git stash list
git log --oneline -5
```

Report the results and recommend next steps based on BACKLOG.md priorities.

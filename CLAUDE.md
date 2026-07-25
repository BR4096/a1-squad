# CLAUDE.md

Essential guidance for Claude Code working on Banana Squad.

## Project Overview

**Banana Squad** - PaperBanana-inspired agentic image generation pipeline. Python + Gemini 3 Pro Image API + Claude Code agent teams.

**Codebase**: Multi-agent workflow (Research, Prompt Architect, Generator, Critic) orchestrated by a Lead agent to produce 5 image variants per request.

## Session Start

**Every new session**: Run `/startup` to initialize context and verify the environment.

This runs `scripts/session-startup.sh` (environment checks, git state, reference image counts) and then reviews PROJECT-STATE.md, DEVLOG.md, and BACKLOG.md to recommend session priorities.

If the user hasn't run `/startup` and starts asking about project state or begins work, proactively suggest: _"Want me to run `/startup` first to check the environment and review project state?"_

## Breaking Changes (MANDATORY)

| Rule | Details |
|------|---------|
| Narrative prompts only | Descriptive paragraphs, NEVER keyword lists |
| Always 5 variants | Faithful, Enhanced, Alt Composition, Style Variation, Bold/Creative |
| Uppercase K resolution | `"2K"` not `"2k"` — API rejects lowercase |
| Never commit `.env` | Contains `GEMINI_API_KEY` |
| Respect specific references | If user provides a path, analyze ONLY that file — no broad scanning |
| Use venv Python | Always run via `.venv/bin/python3`, never system Python |
| No `print()` for secrets | Never log API keys or credentials |

## Essential Commands

```bash
.venv/bin/python3 generate.py           # Test API connectivity
.venv/bin/pip install -r requirements.txt  # Install dependencies
.venv/bin/python3 -m pytest              # Run tests
.venv/bin/python3 -m pytest --cov        # Run tests with coverage
ruff check .                             # Lint
ruff format .                            # Format
```

## Decision Trees

### File Creation

```
Generation script  → generate.py or scripts/
Agent prompt       → .claude/skills/banana-image-gen/references/
Reference image    → reference-images/{style,composition,subject,brand,output-examples}/
Generated output   → outputs/{concept}-v{N}-{variant}.png
Documentation      → docs/
Test file          → tests/test_{module}.py
```

### Error Debugging

```
API 429 error      → Free-tier quota exhausted; wait or enable billing
API auth error     → Check GEMINI_API_KEY in .env
No image returned  → Safety filter triggered; rephrase prompt
Blurry output      → Add image_size="2K" or "4K" (uppercase K)
Import error       → Activate venv: source .venv/bin/activate
```

## Critical Patterns

### API Call Pattern

```python
import os
from google import genai
from google.genai import types
from PIL import Image
from dotenv import load_dotenv

load_dotenv()
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

response = client.models.generate_content(
    model="gemini-3-pro-image-preview",
    contents=["Your narrative prompt here"],
    config=types.GenerateContentConfig(
        response_modalities=['TEXT', 'IMAGE'],
        image_config=types.ImageConfig(
            aspect_ratio="16:9",
            image_size="2K",
        ),
    )
)

for part in response.parts:
    if part.text is not None:
        print(part.text)
    elif part.inline_data is not None:
        image = part.as_image()
        image.save("outputs/my-image.png")
```

### Error Handling

```python
try:
    response = client.models.generate_content(...)
except Exception as e:
    msg = str(e)
    # Never log: api_key, credentials, tokens
    print(f"Generation failed: {msg}")
```

## Architecture

### Tech Stack

- **Language**: Python 3.14+
- **Image Generation**: Gemini 3 Pro Image API (`gemini-3-pro-image-preview`)
- **SDK**: `google-genai`, `Pillow`, `python-dotenv`
- **Agent Framework**: Claude Code experimental agent teams
- **Linting**: ruff
- **Testing**: pytest

### The PaperBanana Pipeline

```
User Request
    |
[Phase 0: GATHER REQUIREMENTS] <- Ask user clarifying questions (MANDATORY)
    |
[Phase 1: RETRIEVER]           <- Analyze specific reference images
    |
[Phase 2: PLANNER]             <- Write detailed narrative description
    |
[Phase 3: STYLIST]             <- Refine with aesthetic guidelines
    |
[Phase 4: VISUALIZER]          <- Generate 5 image variants via Gemini API
    |
[Phase 5: CRITIC]              <- Rank outputs, recommend best, offer iteration
    |
Final Output (5 variants in outputs/)
```

### Agent Team Architecture

| PaperBanana Agent | Team Role | Responsibility |
|---|---|---|
| -- | **Lead (Orchestrator)** | Coordinates pipeline, asks user questions, synthesizes results |
| Retriever | **Research Agent** | Analyzes reference images, gathers context |
| Planner + Stylist | **Prompt Architect** | Writes and refines narrative image descriptions |
| Visualizer | **Generator Agent** | Executes Gemini API calls, produces 5 variants |
| Critic | **Critic Agent** | Reviews outputs, ranks them, suggests refinements |

## Key Files & Folders

| Path | Purpose |
|---|---|
| `docs/eng/gemini-3-image-api-guide.md` | Complete Gemini 3 Pro Image API reference |
| `docs/eng/paperbanana.md` | Original PaperBanana research paper |
| `docs/eng/spawn-team-prompt.md` | Prompt template for spawning the agent team |
| `.env` | Contains `GEMINI_API_KEY`. Never commit. |
| `.env.example` | Template for environment variables |
| `reference-images/` | Subfolders: `style/`, `composition/`, `subject/`, `brand/`, `output-examples/` |
| `outputs/` | All generated images |
| `.claude/skills/banana-image-gen/SKILL.md` | Image generation skill spec |
| `generate.py` | Standalone API test script |

## API Config Options

- **Aspect ratios**: `1:1`, `2:3`, `3:2`, `3:4`, `4:3`, `4:5`, `5:4`, `9:16`, `16:9`, `21:9`
- **Resolution**: `"1K"`, `"2K"`, `"4K"` (uppercase K only!)
- **Google Search**: Add `tools=[{"google_search": {}}]` for real-time data
- **Reference images**: Up to 14 in the `contents` array
- **Image-only output**: Set `response_modalities=['IMAGE']`

## Prompting Strategies

### Photorealistic
```
A photorealistic [shot type] of [subject], [action], set in [environment].
Illuminated by [lighting], creating [mood]. Captured with [camera/lens],
emphasizing [textures]. [Aspect ratio].
```

### Stylized / Icons / Stickers
```
A [style] of [subject], featuring [characteristics] and [color palette].
[Line style], [shading style]. Background: [color/transparent].
```

### Text in Images
```
Create a [image type] with the text "[exact text]" in [font style].
Design: [description], colors: [scheme].
```

### Product Mockups
```
A studio-lit product photograph of [product] on [surface].
Lighting: [setup]. Camera: [angle] to showcase [feature].
Sharp focus on [detail]. [Aspect ratio].
```

## Testing

```bash
.venv/bin/python3 -m pytest              # Run all
.venv/bin/python3 -m pytest -v           # Verbose
.venv/bin/python3 -m pytest --cov        # Coverage
.venv/bin/python3 -m pytest tests/test_generate.py  # Specific file
```

Use AAA pattern (Arrange, Act, Assert). Tests in `tests/`.

## Pre-commit

```bash
# Fast validation
ruff check . && ruff format --check .

# Full validation (before push)
ruff check . && ruff format --check . && .venv/bin/python3 -m pytest
```

## File Organization

- **Scripts**: snake_case (`generate.py`, `batch_generate.py`)
- **Tests**: `tests/test_{module}.py`
- **Imports**: Standard lib, then third-party, then local
- **Config**: `.env` for secrets, `pyproject.toml` for project config

## Session Exit

```bash
ruff check . && git status
```

## Quick Reference

### ADRs (`docs/architecture-decisions/`)

- ADR-001: Use Gemini 3 Pro Image API for generation
- ADR-002: PaperBanana 5-agent architecture
- ADR-003: Python over Node.js for SDK compatibility

### Protocols (from Best-Practices)

- Session Start/Exit: `docs/protocols-ref/`
- Git Commit Batching: Conventional Commits format
- Secrets Management: `.env` + `.gitignore`

---

_Generated from Best-Practices CLAUDE.md template v1.0.0_

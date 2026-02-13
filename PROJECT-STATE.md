# Banana Squad State

Real-time project health snapshot. Updated each session.

**Last Updated**: 2026-02-13 | **Updated By**: Claude

## Status Summary

| Dimension | Status | Notes |
|-----------|--------|-------|
| API | PASS | Gemini 3 Pro Image API verified, billing enabled |
| Tests | N/A | No test suite yet |
| Agent Team | READY | Skill installed, env var set, needs restart to activate |
| Lint | N/A | ruff not yet configured |

## Current Sprint / Focus

**Goal**: Complete project bootstrap and validate end-to-end pipeline

| Item | Status | Owner |
|------|--------|-------|
| Bootstrap infrastructure | Done | -- |
| API connectivity test | Done | -- |
| Best-Practices integration | Done | -- |
| First full agent team run | Pending | -- |
| Populate reference images | Pending | User |

## Known Issues

| Issue | Severity | Status | Notes |
|-------|----------|--------|-------|
| Free-tier quota = 0 | Resolved | Fixed | Linked to GCP billing account |
| No test suite | Low | Open | Add pytest for generate.py |
| No linter configured | Low | Open | Add ruff via pyproject.toml |

## Environment Health

| Environment | Status |
|-------------|--------|
| Python 3.14 venv | Active, deps installed |
| Gemini API | Connected, billing enabled |
| Agent teams | Configured, needs session restart |

## Recent Changes

1. Project bootstrapped with full infrastructure (2026-02-13)
2. API connectivity verified with test image generation (2026-02-13)
3. Best-Practices framework applied, adapted for Python (2026-02-13)

## Next 5 Actions (Next Session)

### 1. Populate reference images
The `reference-images/` subfolders (style/, composition/, subject/, brand/, output-examples/) are all empty. The Research Agent depends on these to analyze visual style. Add 5-10 sample images to unblock the full pipeline.

### 2. Run first full agent team pipeline end-to-end
API is verified working (test-banana-v1.png exists), agents are defined, infrastructure is ready. Spawn the Banana Squad via `/banana-image-gen` and run a simple test request through all 5 phases: Research -> Prompt Architect -> Generator -> Critic. Document results in DEVLOG.md.

### 3. Create `pyproject.toml` and `requirements.txt`
Neither exists yet. Set up pyproject.toml with project metadata, pinned dependencies (google-genai, Pillow, python-dotenv), and ruff/pytest/mypy configuration. Freeze `requirements.txt` from the working venv.

### 4. Add initial test suite for `generate.py`
The `tests/` directory is empty. Create `tests/test_generate.py` with mocked Gemini API responses (success, safety filter, auth error, rate limit) and config validation tests. Use AAA pattern. Run via `.venv/bin/python3 -m pytest`.

### 5. Retrofit with Best-Practices Python stack
Run `Best-Practices/scripts/setup-project.sh --retrofit` to install the new Python settings baseline, slash commands, code templates, and protocol symlinks from the Python stack added to Best-Practices in this session.

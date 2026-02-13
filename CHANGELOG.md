# Changelog

All notable changes to Banana Squad will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Best-Practices framework integration (CLAUDE.md, DEVLOG.md, CHANGELOG.md, PROJECT-STATE.md, BACKLOG.md, AGENTS.md)
- Claude Code commands (startup, resume, review, deploy-check, health)
- Session scripts adapted for Python

### Changed

### Fixed

### Removed

## [0.1.0] - 2026-02-13

### Added
- Project initialization with CLAUDE.md
- `.env` with Gemini API key configuration
- `.gitignore` for Python project
- Python virtual environment (`.venv/`) with dependencies: google-genai, Pillow, python-dotenv
- `generate.py` — standalone API test script (verified working)
- `.claude/skills/banana-image-gen/` — skill definition and agent prompts
- `.claude/settings.local.json` — agent teams enabled
- `reference-images/` subfolder structure (style, composition, subject, brand, output-examples)
- `outputs/` directory for generated images
- Engineering docs: PaperBanana paper, Gemini API guide, spawn team prompt

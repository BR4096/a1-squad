# Backlog - Banana Squad

Product backlog organized by priority. Items move to DEVLOG when actively worked.

## Priority Legend

- **P0**: Critical - blocks release or causes data loss
- **P1**: High - significant user impact, next sprint candidate
- **P2**: Medium - improvement, schedule when capacity allows
- **P3**: Low - nice to have, backlog indefinitely OK

## P0 - Critical

<!-- Items that block release or cause data loss -->

## P1 - High

- [ ] Run first full agent team pipeline end-to-end
- [ ] Add reference images to each subfolder for Research Agent
- [ ] Implement iterative refinement loop (Critic -> Generator, 3 rounds per PaperBanana)

## P2 - Medium

- [ ] Configure ruff linter via pyproject.toml
- [ ] Add pytest test suite for generate.py
- [ ] Add rate limiting / retry logic to generation script
- [ ] Add batch generation script for multiple concepts
- [ ] Create .env.example template

## P3 - Low

- [ ] Add image metadata (EXIF) with prompt used for generation
- [ ] Add cost tracking per API call
- [ ] Explore Gemini 2.5 Flash (Nano Banana) for faster/cheaper drafts
- [ ] Add multi-turn chat editing support
- [ ] Add Google Search grounding for real-time data in images

## Completed

- [x] Project bootstrap (2026-02-13)
- [x] API connectivity verified (2026-02-13)
- [x] Best-Practices framework integration (2026-02-13)

---

_Template from Best-Practices v1.0.0_

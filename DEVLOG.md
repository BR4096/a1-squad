# DEVLOG - Banana Squad

Decision narratives, implementation notes, and work-in-progress tracking.

## Work In Progress

<!-- Active work items. Clear when completed. -->

### Current Focus
- [ ] Populate reference-images/ with sample images
- [ ] Test full agent team pipeline end-to-end
- [ ] Add iterative refinement loop (Critic -> Generator feedback, 3 rounds)

### Blocked
<!-- Items waiting on external input or dependencies -->

---

## Decision Log

<!-- Append new entries at the top. Format: ### YYYY-MM-DD: Decision Title -->

### 2026-02-13: Project Initialization & Best-Practices Integration

**Context**: Banana Squad project bootstrapped with API connectivity verified. Applied Best-Practices framework adapted for Python.

**Decision**: Use Python (not Node.js) as the primary language, with google-genai SDK for Gemini API calls.

**Rationale**: The PaperBanana paper uses Python examples, the google-genai Python SDK is more mature for image generation, and PIL/Pillow is the standard for image handling in Python.

### 2026-02-13: Gemini API Billing

**Context**: Free-tier quota was exhausted immediately on first test.

**Decision**: Linked API key to GCP billing account for pay-per-use access.

**Rationale**: Free tier has zero quota for gemini-3-pro-image model. Paid tier required for any image generation work.

---

_Template from Best-Practices v1.0.0_

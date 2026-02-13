# ADR-001: Use Gemini 3 Pro Image API for Generation

**Date**: 2026-02-13
**Status**: Accepted

## Context

The PaperBanana framework requires a state-of-the-art image generation model. Options considered:
- Gemini 3 Pro Image (Nano Banana Pro)
- GPT-Image-1.5
- Stable Diffusion / SDXL

## Decision

Use `gemini-3-pro-image-preview` (Nano Banana Pro) as the default generation model.

## Rationale

- PaperBanana benchmark results show Nano Banana Pro significantly outperforms GPT-Image-1.5 across all 4 evaluation dimensions
- Native text rendering capability (critical for diagrams and labels)
- Up to 4K resolution and 14 reference image input
- Thinking mode for complex compositions
- Google Search grounding for real-time data

## Consequences

- Requires GCP billing account for production use (free tier has near-zero quota)
- API is in preview — model ID may change
- Python SDK (`google-genai`) is the primary integration path

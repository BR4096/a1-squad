# Banana Squad

PaperBanana-inspired agentic image generation pipeline. Uses a multi-agent team (Research, Prompt Architect, Generator, Critic) coordinated by a Lead to produce 5 image variants per request via the Gemini 3 Pro Image API.

## Quick Start

```bash
# 1. Set up environment
cp .env.example .env        # Add your GEMINI_API_KEY
source .venv/bin/activate
pip install -r requirements.txt

# 2. Test API connectivity
python generate.py

# 3. Run the agent team
# Use /banana-image-gen in Claude Code to spawn the full pipeline
```

## Project Structure

```
a1-squad/
  generate.py              # Standalone API test script
  reference-images/        # Input references for the pipeline
    GUIDELINES.md          #   Naming, format, and category rules
    manifest.yaml          #   Image catalog (update when adding/removing)
    style/                 #   Aesthetic style references
    composition/           #   Layout and spatial arrangement refs
    subject/               #   Core products, people, objects
    brand/                 #   Logos, palettes, typography
    output-examples/       #   Gold-standard target outputs
  outputs/                 # Generated images land here
  docs/
    eng/                   # Engineering references
    architecture-decisions/ # ADRs
  scripts/                 # Utility scripts
  tests/                   # pytest test suite
```

## Reference Images

The pipeline's Research Agent uses reference images to ground generation in your visual style and brand. Before running the full pipeline, populate the `reference-images/` library.

- **[GUIDELINES.md](reference-images/GUIDELINES.md)** -- Naming conventions, format/resolution rules, minimum images per category, and tips for sourcing references
- **[manifest.yaml](reference-images/manifest.yaml)** -- Catalog of all reference images with descriptions, use cases, and tags. Update this file whenever you add or remove images.

Minimum **20 images** across 5 categories to have a functional library. See the guidelines for priority order when starting from scratch.

## The Pipeline

```
User Request
    |
[Phase 0: GATHER REQUIREMENTS]   Ask clarifying questions
    |
[Phase 1: RETRIEVER]             Analyze reference images
    |
[Phase 2: PLANNER]               Write detailed narrative description
    |
[Phase 3: STYLIST]               Refine with aesthetic guidelines
    |
[Phase 4: VISUALIZER]            Generate 5 variants via Gemini API
    |
[Phase 5: CRITIC]                Rank outputs, recommend best, offer iteration
    |
Final Output (5 variants in outputs/)
```

Every run produces 5 variants: Faithful, Enhanced, Alt Composition, Style Variation, and Bold/Creative.

## Key Documentation

| Document | Purpose |
|---|---|
| [CLAUDE.md](CLAUDE.md) | Agent instructions and project conventions |
| [PROJECT-STATE.md](PROJECT-STATE.md) | Current sprint status and known issues |
| [reference-images/GUIDELINES.md](reference-images/GUIDELINES.md) | Reference image standards |
| [reference-images/manifest.yaml](reference-images/manifest.yaml) | Reference image catalog |
| [docs/eng/gemini-3-image-api-guide.md](docs/eng/gemini-3-image-api-guide.md) | Gemini 3 Pro Image API reference |
| [docs/eng/paperbanana.md](docs/eng/paperbanana.md) | PaperBanana research paper |

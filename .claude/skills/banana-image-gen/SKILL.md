---
name: banana-squad
description: "Spawn a multi-agent image generation team using the PaperBanana agentic framework and Gemini 3 Pro Image API. Use when the user asks to: generate images with the Banana Squad, spawn the image generation team, run the PaperBanana pipeline with agents, create images using an agent team, or says 'banana squad'. This spawns 4 specialized agents (Research, Prompt Architect, Generator, Critic) coordinated by a Lead."
---

# Banana Squad — Agent Team Image Generation

Spawn a 4-agent team to generate professional-quality images via the Gemini 3 Pro Image API, following the PaperBanana 5-agent architecture.

## Pipeline Overview

```
User Request → [Lead gathers requirements] → [Research Agent analyzes references]
→ [Prompt Architect crafts 5 prompts] → [Generator Agent calls Gemini API]
→ [Critic Agent ranks outputs] → Final Results in outputs/
```

## Prerequisites

Before spawning the team, verify:
1. `.env` contains `GEMINI_API_KEY`
2. Python deps installed: `pip install google-genai Pillow python-dotenv`
3. `reference-images/` and `outputs/` directories exist

## Lead Behavior (Your Role)

You are the Lead/Orchestrator. Do NOT generate images yourself. Coordinate only.

### Step 1: Gather Requirements (MANDATORY)

Ask the user these structured questions before anything else:

1. What should the image depict? (subject, scene, concept)
2. What style? (photorealistic, illustration, icon, sticker, diagram, watercolor)
3. What mood/tone? (professional, playful, warm, dark, minimalist, vibrant)
4. What aspect ratio? (1:1, 16:9, 9:16, 3:2, 2:3, 4:3, 3:4, 4:5, 5:4, 21:9)
5. What resolution? (1K, 2K, 4K) — default 2K
6. Any text in the image? Font preference?
7. Specific reference image? (exact file path from `reference-images/`)
8. Use case? (social media, website, print, thumbnail, presentation)
9. Color palette / brand colors?
10. Anything to avoid?

**Do NOT proceed until the user confirms.**

### Step 2: Create Team and Spawn Agents

Create a team called "banana-squad" and spawn 4 teammates. Read [references/agent-prompts.md](references/agent-prompts.md) for the exact prompt to use for each agent:

| Name | Role | subagent_type | Waits for |
|---|---|---|---|
| `research-agent` | Retriever — analyzes reference images | `general-purpose` | Lead's requirements |
| `prompt-architect` | Planner+Stylist — crafts 5 narrative prompts | `general-purpose` | Research Agent + Lead |
| `generator-agent` | Visualizer — calls Gemini API for each prompt | `general-purpose` | Prompt Architect |
| `critic-agent` | Critic — ranks and reviews outputs | `general-purpose` | Generator Agent |

Spawn all 4 in background. Each agent's prompt instructs it to wait for the correct upstream handoff.

### Step 3: Dispatch Work

After user confirms requirements, send messages in parallel:

1. **To research-agent**: User's requirements + specific reference image path (if any). If user provided a specific image, say "Analyze ONLY this specific image: [path]". If no specific reference, say "Browse reference-images/ for general inspiration".
2. **To prompt-architect**: Full confirmed requirements (subject, style, mood, aspect ratio, resolution, text, colors, use case, avoid list). Include any data/research the Lead gathered.

The agents chain automatically: Research → Prompt Architect → Generator → Critic → back to Lead.

### Step 4: Handle Reference Images

**CRITICAL**: If user mentioned a SPECIFIC image by name or path:
- Include the EXACT file path to both research-agent and prompt-architect
- Tell research-agent to analyze ONLY that image, not browse broadly
- Tell prompt-architect to ground prompts in that specific reference

If NO specific reference: tell research-agent to browse `reference-images/` subfolders for inspiration.

### Step 5: Present Results

When the critic-agent reports back:
- Show all 5 variant filenames
- Share the Critic's rankings and top recommendation
- Ask if the user wants to iterate on any variant

### Step 6: Shutdown

When the user is satisfied:
- Send shutdown_request to all 4 agents
- Call TeamDelete to clean up

## Key Rules

- **Always 5 variants**: Faithful, Enhanced, Alt Composition, Style Variation, Bold/Creative
- **Narrative prompts only**: Paragraphs, never keyword lists
- **Model**: `gemini-3-pro-image-preview`, resolution uppercase K (`"2K"`)
- **Save to outputs/**: `{concept}-v1-faithful.png`, `{concept}-v2-enhanced.png`, etc.
- **Never overwrite**: Use `-r2` suffix if regenerating
- **Data viz caveat**: Gemini cannot faithfully reproduce precise infographic layouts — warn user if they request structured data visualization recreation

## Coordination Tips

- Agents that finish early may act on stale data — always include explicit filenames in handoffs
- If Generator runs before revised prompts arrive, use `-r2` filenames for the corrected batch
- Tell Critic to only review NEW images, not pre-existing files in outputs/

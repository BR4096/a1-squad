# Agents - Banana Squad

Claude Code agent configurations for this project.

## Active Agents

| Agent | Category | Purpose |
|-------|----------|---------|
| Research Agent (Retriever) | Image Analysis | Analyzes reference images, extracts style/composition details |
| Prompt Architect (Planner+Stylist) | Content Generation | Crafts 5 narrative image prompts from requirements + research |
| Generator Agent (Visualizer) | Image Generation | Calls Gemini 3 Pro API, produces 5 image variants |
| Critic Agent | Quality Assurance | Reviews outputs on faithfulness, conciseness, readability, aesthetics |

## Agent Locations

- **Skill definition**: `.claude/skills/banana-image-gen/SKILL.md`
- **Agent prompts**: `.claude/skills/banana-image-gen/references/agent-prompts.md`
- **Spawn prompt**: `docs/eng/spawn-team-prompt.md`

## Usage

The agent team is spawned as a group via the Banana Squad skill or by pasting the spawn prompt from `docs/eng/spawn-team-prompt.md`.

Requires: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `.claude/settings.local.json`

## Pipeline Flow

```
Lead (you) --> Research Agent --> Prompt Architect --> Generator Agent --> Critic Agent --> Lead
```

Each agent waits for its upstream dependency before starting work. The Lead coordinates handoffs and presents final results to the user.

## Evaluation Dimensions (from PaperBanana)

| Dimension | What It Measures |
|-----------|-----------------|
| Faithfulness | Alignment with user's request |
| Conciseness | Focus on core information, no visual clutter |
| Readability | Clear layout, legible text, clean composition |
| Aesthetics | Professional appearance, visual appeal |

See `Best-Practices/agents/README.md` for the full agent catalog and templates.

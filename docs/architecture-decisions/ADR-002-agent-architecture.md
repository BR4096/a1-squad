# ADR-002: PaperBanana 5-Agent Architecture

**Date**: 2026-02-13
**Status**: Accepted

## Context

Need to decide how to structure the image generation workflow — single-pass vs. multi-agent pipeline.

## Decision

Implement the PaperBanana 5-agent architecture (Retriever, Planner, Stylist, Visualizer, Critic) using Claude Code experimental agent teams.

## Rationale

- PaperBanana ablation study shows each agent contributes measurable quality improvements
- Retriever provides stylistic grounding (+17.5% conciseness with Stylist)
- Critic's iterative refinement (3 rounds) recovers faithfulness lost during aesthetic polish
- Full pipeline achieved 72.7% win rate vs. vanilla generation in blind human evaluation
- Claude Code agent teams allow parallel execution and natural language coordination

## Consequences

- Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` feature flag
- More complex than single-pass; harder to debug when agents miscommunicate
- Each generation costs multiple API calls (5 variants x potential retries)

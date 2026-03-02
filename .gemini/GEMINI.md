# Gemini Instructions: `awesome-copilot-opensource` (PHP Edition)

## Current Project Phase
**Phase 1: Foundation & Standardization** (See [ROADMAP.md](ROADMAP.md))
- We have established a PHP-centric focus.
- We have standardized the agent pack structure (including `manifest.json`).
- We are building the SimPrompt installer (coming soon).

## Core Mandates
1.  **PHP Focus:** All agents and instructions must prioritize the PHP ecosystem (Laravel/Symfony).
2.  **Cross-AI Compatibility:** Ensure all prompts and agent markdown files are compatible with GitHub Copilot, Gemini CLI, Junie, Claude Code, and Cursor.
3.  **Strict Structure:** All new agent packs MUST follow the standardized folder structure:
    - `packs/<name>/manifest.json`
    - `packs/<name>/stubs/`
4.  **Verification-First:** All multi-agent orchestration designs must include a **Phase 2: Hallucination Verification** step to ensure evidence-based results.
5.  **Conventional Commits:** All contributions must follow the Conventional Commits specification.

## Technical Preferences
- **Architecture:** 4-Phase Orchestration (Context -> Parallel Analysis -> Verification -> Risk/Output).
- **Documentation:** Use Mermaid diagrams in `docs/architecture/` for visual flows.
- **SimPrompt Installer:** The long-term goal is a CLI-driven "Manager" for these packs.

## Ongoing Tasks
- [ ] Implement the `manifest.json` for all current agents.
- [ ] Draft the "Phase 0" standard for PHP framework detection.
- [ ] Prepare for the SimPrompt CLI scaffolding.

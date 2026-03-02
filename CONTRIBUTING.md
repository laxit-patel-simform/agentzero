# Contributing to AgentZero (PHP Edition) 🐘

We are thrilled to have you join us as an **Intelligence Engineer**. This project relies on expert knowledge to build the "Brains" of our agent packs.

## 🛠️ Developer Setup

If you want to contribute, you will need to clone the repository and set up the development environment.

### Requirements:
- PHP >= 8.1
- Composer
- GitHub CLI (`gh`)
- `curl`

### Installation:
```bash
git clone https://github.com/simform-git/awesome-copilot-opensource.git
cd awesome-copilot-opensource
make doctor
```

## 🏗️ Workflow: Intelligence Engineering (SOP)

1.  **Initialize Agent:** Create a folder in `agents/` (e.g., `agents/php-testing/`).
2.  **Scaffold Stubs:** Every agent must have a `stubs/` directory mirroring the target `.github/` structure.
3.  **Define Manifest:** Fill out `agents/<id>/manifest.json` with metadata.
4.  **Register:** Add your agent to the root `registry.json`.
5.  **Verify:** Run `make verify` to ensure structural integrity.

Detailed SOP available at: **[docs/SOP.md](docs/SOP.md)**.

## 🧬 Intelligence Standards

- **Cross-AI Readiness:** Ensure prompts are compatible with Copilot, Gemini, Claude, and more.
- **Single Responsibility:** Each sub-agent should do one thing well (e.g., *only* security, *only* linting).
- **Verification First:** All orchestration flows MUST include a hallucination verification phase (Phase 2).

## 💬 Communication
- Use **Conventional Commits** (`feat:`, `fix:`, `docs:`, etc.) for all PRs.
- Propose new packs or major architectural changes via GitHub Issues.

---
*By contributing, you agree to follow our Code of Conduct.*

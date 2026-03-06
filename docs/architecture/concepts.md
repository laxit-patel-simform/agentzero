# Core Concepts: Intelligence vs. AgentZero

To understand `awesome-copilot-opensource`, it is helpful to use a classic software engineering analogy: **Intelligence vs. AgentZero.**

## 1. The "Intelligence" (Brains & Orchestration)
The "Core" of this project is the **Intelligence**. This includes:
- **Instruction Sets:** Expert-level rules for PHP, Laravel, and Symfony.
- **Orchestration Workflows:** The 4-Phase pipeline (Context -> Analysis -> Verification -> Output).
- **Evaluation Rubrics:** How to score a PR or a security vulnerability.

This **Intelligence** is the intellectual property of our repository, refined and tested to work across multiple AI assistants.

## 2. The "Stubs" (The Payload)
Our "Compiled" deliverables are the **Stubs**—standardized files that modern IDEs and AI assistants understand:
- **`.github/agents/`**: Defines specialized personas.
- **`.github/prompts/`**: Defines reusable slash commands.
- **`.github/instructions/`**: Defines contextual rules.

### Why "Stubs" are Mandatory
To maintain a professional deployment workflow, we enforce a strict `stubs/` directory for all agents:
1. **Clean Deployment:** The `bin/agentzero.sh` installer copies the *entire* `stubs/` directory into the target project. This ensures only the "payload" is shipped, leaving behind internal documentation, tests, and metadata (like `manifest.json`).
2. **Payload Mirroring:** The directory structure inside `stubs/` (e.g., `stubs/.github/`) mirrors exactly where the files will land in the user's repository, making the installation logic simple and predictable.
3. **Source vs. Dist:** We treat the agent's root as "Source" (logic, README, meta) and the `stubs/` folder as "Distribution" (the actual markdown files the AI reads).

We use **Markdown + YAML frontmatter** as our standardized format for these **Stubs** because it is the most widely supported protocol across AI agents.

## 3. The "AgentZero" (Discovery & Automation)
How do these high-value **Stubs** get into a developer's project?
- **AgentZero (Primary):** The "Root Agent" that automates the deployment of packs, manages versions, and checks for framework compatibility. It acts as an intelligent bridge between our repository and the developer's workspace.
- **Manual Copy-Paste (Secondary):** A fallback method for users who want to manually integrate specific files.

## 4. Interoperability (Cross-AI)
Because our **Intelligence** is decoupled from the **AgentZero** automation and uses a standardized **Stub** format, it is compatible across multiple AI ecosystems:
- **GitHub Copilot** (Native integration)
- **Gemini CLI** (Instruction injection)
- **Claude Code / Junie** (Task-based execution)
- **Cursor** (.cursorrules compatible)

---

**Summary:** We are building **Portable Intelligence for PHP Developers**, with **AgentZero** as the meta-agent for discovering and deploying our **Stubs**.

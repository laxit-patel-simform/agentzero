# Project Terms & Naming Conventions

This document defines the core terminology used in `awesome-copilot-opensource` and provides analogies to standard software engineering concepts for easier developer onboarding.

## Core Naming Conventions & Developer Analogies

### 1. Agent Pack (or "Pack")
**Definition:** The atomic unit of installation. A coordinated bundle of Intelligence and Assets.
- **Software Analogy:** **Package / Module** (e.g., a Composer package or an NPM module).
- **Location:** `packs/<pack-name>/`

### 2. Intelligence
**Definition:** The expert prompts, 4-phase orchestration strategies, and evaluation rubrics.
- **Software Analogy:** **Business Logic / Domain Layer**. This is the code that defines "how" the system solves a problem.
- **Format:** Markdown + YAML frontmatter.

### 3. Stubs
**Definition:** The standardized files (`.github/agents`, etc.) that are transported into a user's repository. These are the high-value templates that an IDE (VS Code, Cursor) or an AI (Copilot, Gemini) reads to execute the **Intelligence**.
- **Software Analogy:** **Asset Templates / Payload** (e.g., `.stub` files in Laravel or Boilerplate).
- **Location:** `packs/<pack-name>/stubs/`

### 4. Deploy (The Script & SSH Showcase)
**Definition:** The mechanism used to move **Stubs** from this repository into a developer's project.
- **Software Analogy:** **Universal Installer Script** (e.g., `curl | bash`) and **Remote CLI Menu**.
- **Primary Method:** 
  - **SimPrompt Script (`simprompt.sh`):** The zero-dependency tool for local deployment.
  - **SimPrompt SSH (`ssh simprompt.com`):** A remote interactive menu for browsing and discovering **Packs**.



### 5. Orchestrator
**Definition:** A lead prompt that coordinates the work of multiple Sub-Agents.
- **Software Analogy:** **Controller / Service Coordinator**. It manages the flow between different specialized components.

### 6. Sub-Agent
**Definition:** A specialized agent with a "Single Responsibility."
- **Software Analogy:** **Microservice / Single Responsibility Class**. A small, focused unit that does one thing well (e.g., Linting).

### 7. Phase 0 (Context Extraction)
**Definition:** The step where the AI detects the project's framework and rules.
- **Software Analogy:** **Environment Bootstrapping / Dependency Injection**. Setting up the context before execution begins.

### 8. Phase 2 (Hallucination Verification)
**Definition:** A mandatory step where an independent agent verifies findings against the PR diff.
- **Software Analogy:** **Unit Testing / Assertions**. A safety layer that ensures the output is correct before it is "shipped" to the user.

## Folder Taxonomy

| Folder | Developer Analogy | Purpose |
| :--- | :--- | :--- |
| `packs/` | `src/` or `lib/` | Source of truth for all **Agent Packs**. |
| `cli/` | `bin/` or `tools/` | Source code for the **SimPrompt** CLI. |
| `docs/` | `docs/` | High-level **Intelligence** architecture. |
| `samples/` | `examples/` | Example "Consumer" repositories for testing. |

---

**Note:** Always use these terms in PRs, commit messages, and documentation to maintain clarity.

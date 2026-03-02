# Project Terms & Naming Conventions

This document defines the core terminology used in `awesome-copilot-opensource` and provides analogies to standard software engineering concepts for easier developer onboarding.

## Core Naming Conventions & Developer Analogies

### 1. Agent
**Definition:** The atomic unit of installation. A coordinated bundle of **Intelligence** and **Stubs** that provides a specific capability (e.g., `php-code-review`).
- **Software Analogy:** **Package / Module** (e.g., a Composer package or an NPM module).
- **Location:** `agents/<agent-id>/`

### 2. Intelligence
**Definition:** The expert prompts, 4-phase orchestration strategies, and evaluation rubrics.
- **Software Analogy:** **Business Logic / Domain Layer**. This is the code that defines "how" the system solves a problem.
- **Format:** Markdown + YAML frontmatter.

### 3. Stubs
**Definition:** The standardized files (`.github/agents`, etc.) that are transported into a user's repository. These are the high-value templates that an IDE (VS Code, Cursor) or an AI (Copilot, Gemini) reads to execute the **Intelligence**.
- **Software Analogy:** **Asset Templates / Payload** (e.g., `.stub` files in Laravel or Boilerplate).
- **Location:** `agents/<agent-id>/stubs/`

### 4. AgentZero (The Meta-Agent)
**Definition:** The "Root Agent" responsible for automating the discovery and deployment of **Agents** into a project.
- **Software Analogy:** **Installer Meta-Agent / Project Bootstrapper**.
- **Primary Function:** **AgentZero** interviews the user, detects the tech stack (Laravel/Symfony), and dynamically "deploys" the correct **Stubs** formatted for the user's specific AI assistant.

### 5. Orchestrator
**Definition:** A lead prompt that coordinates the work of multiple Sub-Agents.
- **Software Analogy:** **Controller / Service Coordinator**. It manages the flow between different specialized components.

### 6. Sub-Agent
**Definition:** A specialized agent with a "Single Responsibility" (e.g., a "Linting Agent"). They provide raw data to the Orchestrator.

### 7. Phase 0 (Context Extraction)
**Definition:** The step where the AI detects the project's framework and rules.
- **Software Analogy:** **Environment Bootstrapping / Dependency Injection**.

### 8. Intelligence Engineer
**Definition:** A developer who specializes in building, refining, and testing the **Intelligence** for Agents.
- **Role:** Primary contributors who engineer the "Brains" of the system.

## Folder Taxonomy

| Folder | Developer Analogy | Purpose |
| :--- | :--- | :--- |
| `agents/` | `src/` or `lib/` | Source of truth for all **Agents**. |
| `bin/` | `bin/` or `tools/` | Source code for the **AgentZero** tools. |
| `docs/` | `docs/` | High-level **Intelligence** architecture and project terms. |
| `samples/` | `examples/` | Example "Consumer" repositories for testing. |

---

**Note:** Always use these terms in PRs, commit messages, and documentation to maintain clarity.

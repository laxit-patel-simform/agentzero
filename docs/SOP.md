# Standard Operating Procedures (SOP)

This document outlines the two primary workflows of the `awesome-copilot-opensource` project: **Intelligence Engineering** (for contributors) and **Deployment** (for consumers).

---

## 🏗️ SOP: Intelligence Engineering (The Contributor)
*Goal: Build, refine, and ship a high-quality Agent Pack for the PHP community.*

1.  **Initialize Pack:** Create a new folder in `packs/` (e.g., `packs/php-testing/`).
2.  **Scaffold Structure:** Create the mandatory sub-directories:
    - `packs/<id>/manifest.json`
    - `packs/<id>/stubs/.github/agents/`
    - `packs/<id>/stubs/.github/prompts/`
    - `packs/<id>/stubs/.github/instructions/`
3.  **Engineer Intelligence:** Write the expert prompts and orchestration logic in the markdown files within `stubs/`.
4.  **Register:**
    - Fill out the `manifest.json` with metadata and file lists.
    - Add the pack ID and details to the root `registry.json`.
5.  **Verify Integrity:** Run `make verify` from the project root. All tests must pass.
6.  **Merge:** Submit a PR using **Conventional Commits** style.

---

## 🚀 SOP: Consumer Deployment (The User)
*Goal: Activate AgentZero and deploy a specific Intelligence Pack into your PHP project.*

### Step 1: Discover (Remote Call)
The user doesn't clone this repo. They interact with it remotely:
```bash
curl -sSL https://raw.githubusercontent.com/simform-git/awesome-copilot-opensource/main/bin/agentzero.sh | bash -s -- list
```

### Step 2: Health Check
Run the "doctor" command to ensure the local environment is ready:
```bash
curl -sSL https://raw.githubusercontent.com/simform-git/awesome-copilot-opensource/main/bin/agentzero.sh | bash -s -- doctor
```

### Step 3: Deploy
Choose a pack ID from the list and deploy it into your project's `.github/` folder:
```bash
curl -sSL https://raw.githubusercontent.com/simform-git/awesome-copilot-opensource/main/bin/agentzero.sh | bash -s -- deploy <pack-id>
```

### Step 4: Activate
Restart your IDE's AI assistant (Copilot Chat, Gemini, etc.). The new specialized agents and prompts are now active in your workspace.

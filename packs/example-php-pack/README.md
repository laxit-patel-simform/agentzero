# Example PHP Agent Pack 🐘

This is a boilerplate **Agent Pack** for PHP developers. It demonstrates the **Intelligence + Stubs** architecture.

## What's Inside?

### 1. Intelligence
- **Orchestrator Persona:** A Senior PHP Developer.
- **Workflow:** High-level code review via `/review` command.
- **Rules:** PSR-12 and framework-specific patterns.

### 2. Stubs (Assets)
This pack provides the following files to be installed into your project root's `.github/` folder:
- `.github/agents/example.agent.md`
- `.github/prompts/example.prompt.md`
- `.github/instructions/example.instructions.md`

## Installation

### Method A: SimPrompt Script (Coming Soon)
```bash
simprompt.sh install example-php-pack
```

### Method B: Manual
1.  Copy the `stubs/.github/` folder into your repository root.
2.  Restart your IDE's AI Assistant (e.g., Copilot Chat).

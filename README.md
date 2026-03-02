# Awesome Copilot Open Source (PHP Edition) 🐘

A collection of high-performance, multi-agent **GitHub Copilot Agent Packs** specifically engineered for the **PHP (Laravel/Symfony)** ecosystem.

Designed for professional teams, these agent packs are modular, framework-aware, and built to handle complex tasks like PR reviews, security audits, and architectural evaluations.

## 🚀 Vision: The "SimPrompt" Strategy

Instead of manual copy-pasting, this project is evolving into a **SimPrompt CLI tool** that allows you to:
1.  **Browse** available agent packs.
2.  **Install** them directly into your project's `.github/` folder.
3.  **Manage** and update them as the community improves the prompts.

## 🤖 Cross-AI Compatibility
While optimized for **GitHub Copilot**, these agent packs follow open standards (Markdown + YAML frontmatter) and are compatible with other modern AI coding assistants, including:
- **Gemini CLI**
- **Claude Code**
- **Junie**
- **Cursor**

## 📂 Repository Structure

```
/
├── packs/                # PHP Agent Packs (Metadata + Stubs)
│   ├── example-php-pack/ # Standard Intelligence + Stubs structure
│   └── ...               # Security, Code Review, etc.
├── bin/                  # SimPrompt CLI & Verification scripts
├── docs/                 # Architectural Intelligence & Concepts
├── ROADMAP.md            # The master plan for PHP expansion
└── .github/              # Project-level CI/CD & Automations
```

## 🏗️ Architecture: The 4-Phase Pipeline

All our advanced agents follow a standardized orchestration flow to ensure speed and accuracy:
1.  **Phase 0: Context Extraction** (PHP Framework detection)
2.  **Phase 1: Parallel Analysis** (Specialized sub-agents)
3.  **Phase 2: Hallucination Verification** (Evidence-based checking)
4.  **Phase 3: Risk Scoring & Output** (Actionable reports)

Detailed diagrams can be found in [docs/architecture/php-orchestration.md](docs/architecture/php-orchestration.md).

## 🛠️ Installation (Manual)

*Note: SimPrompt CLI is in development.*

1.  Copy the desired `stubs/.github/` folder from a pack in `packs/`.
2.  Paste contents into your repository's root `.github/` folder.
3.  Ensure you have a `project-constitution.md` in your root for custom rules.

## 🤝 Contributing

We follow **Conventional Commits** for all PRs. See [ROADMAP.md](ROADMAP.md) for upcoming tasks.

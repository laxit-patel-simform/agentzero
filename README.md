# Awesome Copilot Open Source (PHP Edition) 🐘

A collection of high-performance, multi-agent **GitHub Copilot Agent Packs** specifically engineered for the **PHP (Laravel/Symfony)** ecosystem.

Designed for professional teams, these agent packs are modular, framework-aware, and built to handle complex tasks like PR reviews, security audits, and architectural evaluations.

## 🚀 Vision: The "Manager" Strategy

Instead of manual copy-pasting, this project is evolving into a **TUI (Terminal User Interface) CLI tool** that allows you to:
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
├── agents/               # PHP Agent Packs (Metadata + Agent Files)
│   ├── code-review/      # PR Review Suite (Parallel Orchestration)
│   ├── security-audit/   # OWASP-based Security Scanning
│   └── ...               # Architect, Estimation, etc.
├── cli/                  # (Coming Soon) TUI Installer source code
├── docs/                 # Architectural Documentation & Mermaid Diagrams
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

*Note: TUI Installer is in development.*

1.  Copy the desired agent folder from `agents/`.
2.  Paste contents into your repository's `.github/` folder.
3.  Ensure you have a `project-constitution.md` in your root for custom rules.

## 🤝 Contributing

We follow **Conventional Commits** for all PRs. See [ROADMAP.md](ROADMAP.md) for upcoming tasks.

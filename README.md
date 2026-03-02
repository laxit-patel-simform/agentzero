```text
  █████╗  ██████╗ ███████╗███╗   ██╗████████╗███████╗███████╗██████╗  ██████╗ 
 ██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝╚══███╔╝██╔════╝██╔══██╗██╔═══██╗
 ███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║     ███╔╝ █████╗  ██████╔╝██║   ██║
 ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║    ███╔╝  ██╔══╝  ██╔══██╗██║   ██║
 ██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║   ███████╗███████╗██║  ██║╚██████╔╝
 ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ 
```

# Awesome Copilot Open Source (PHP Edition) 🐘

A collection of high-performance, multi-agent **Intelligence Packs** specifically engineered for the **PHP (Laravel/Symfony)** ecosystem.

Designed for professional teams, these packs are modular, framework-aware, and built to handle complex tasks like PR reviews, security audits, and architectural evaluations.

## 🚀 Vision: The AgentZero Meta-Agent

Instead of manual copy-pasting, this project uses **AgentZero**—an intelligent meta-agent that automates the discovery and deployment of specialized **Intelligence** into your repository.

## 🤖 Cross-AI Compatibility
Our **Intelligence** follows standardized Markdown/YAML formats and is compatible with:
- **GitHub Copilot**
- **Gemini CLI**
- **Claude Code**
- **Junie**
- **Cursor**

## 📂 Repository Structure

```
/
├── packs/                # Source of truth for Agent Packs (Intelligence + Stubs)
│   ├── example-php-pack/ # Boilerplate pack
│   └── ...               # Security, Code Review, etc.
├── bin/                  # AgentZero CLI & Verification scripts
├── docs/                 # Architectural Intelligence, Concepts & SOPs
├── ROADMAP.md            # The master plan for PHP expansion
├── registry.json         # The central discovery registry
└── .github/              # Project-level CI/CD & Automations
```

## 🏗️ Architecture: The 4-Phase Pipeline

All our advanced agents follow a standardized orchestration flow to ensure speed and accuracy:
1.  **Phase 0: Context Extraction** (PHP Framework detection)
2.  **Phase 1: Parallel Analysis** (Specialized sub-agents)
3.  **Phase 2: Hallucination Verification** (Evidence-based checking)
4.  **Phase 3: Risk Scoring & Output** (Actionable reports)

Detailed diagrams can be found in [docs/architecture/php-orchestration.md](docs/architecture/php-orchestration.md).

## 🚀 Getting Started (SOP)

For detailed workflows, see **[Standard Operating Procedures (SOP)](docs/SOP.md)**.

### For Users (Zero-Cloning Deploy)
```bash
# List available packs
curl -sSL https://raw.githubusercontent.com/simform-git/awesome-copilot-opensource/main/bin/agentzero.sh | bash -s -- list

# Deploy a pack
curl -sSL https://raw.githubusercontent.com/simform-git/awesome-copilot-opensource/main/bin/agentzero.sh | bash -s -- deploy php-code-review
```

### For Intelligence Engineers (Contributors)
```bash
git clone https://github.com/simform-git/awesome-copilot-opensource.git
make help
make verify
```

## 🤝 Contributing

We follow **Conventional Commits** for all PRs. See [ROADMAP.md](ROADMAP.md) for upcoming tasks.

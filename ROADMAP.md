# Roadmap: `simform-git/awesome-copilot-opensource` (PHP Edition)

## Phase 1: Core PHP Standardization 🏗️
- [ ] Define `manifest.json` schema for PHP Agent Packs (Metadata, Frameworks)
- [ ] Refactor `agents/` folder to match the PHP-centric standard structure
- [ ] Standardize "Phase 0" (Context Extraction) for PHP (Laravel/Symfony)
- [ ] Create `docs/architecture/php-orchestration.md` with **Mermaid diagrams** for visual flow
- [ ] Implement **Conventional Commits** enforcement (linting commit messages)

## Phase 2: The Envoy Script & SSH Showcase 🛠️
- [ ] Scaffold `envoy.sh` (Universal Bash Installer)
- [ ] Implement `list` function (Interactively browse packs locally)
- [ ] Implement **Envoy SSH (Remote CLI):** A TUI served over SSH for pack discovery
- [ ] Implement `install <pack>` function (Copy Assets to target `.github/`)
- [ ] Implement `doctor` function (Check local PHP, Composer, and Git setup)
- [ ] Support for **Remote Installation** (`curl | bash` or `ssh | sh` patterns)

## Phase 3: PHP Specialized Agent Packs 🐘
- [ ] Finalize "PHP Code Review" Agent (PSR-12, Laravel/Symfony patterns)
- [ ] Finalize "PHP Security Audit" Agent (Reading-focused: OWASP, PHP-specific vulnerabilities)
- [ ] Finalize "PHP Solution Architect" Agent (Enterprise SA patterns for PHP)
- [ ] Create `samples/laravel-app` for end-to-end testing of agent packs

## Phase 4: Expansion & Automation 🌐
- [ ] Add "PHP Technical Debt" Agent (Detecting God objects, complexity in PHP)
- [ ] Add "PHP Project Estimation" Agent (Based on common PHP project sizes)
- [ ] Add MCP (Model Context Protocol) support for PHP tools (PHPUnit, PHPStan)
- [ ] **CI/CD Integration:** Automate verification of commit names and agent tests upon merge

## Phase 5: Governance & PHP Community 🤝
- [ ] Finalize `CONTRIBUTING.md` (PHP-specific agent design rules)
- [ ] Finalize `CODE_OF_CONDUCT.md`
- [ ] Add Licensing

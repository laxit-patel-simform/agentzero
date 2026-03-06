# Code Review Agent

Automated PR review system using **parallel sub-agents**. Works with **any PHP project** (Symfony, Laravel, or standalone PHP).

**Fully Copilot-compatible** | **Parallel execution** | **Minimal setup**

---

## Quick Start

```bash
# Copy to your project
cp -r .github/ /path/to/your-project/

# Review a PR
/pr-review 42

# Review local changes
/code-review

# Generate project standards (optional)
/generate-constitution
```

**See [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for all commands and options.**

---

## How It Works

Parallel multi-phase review:

- **Phase 0** (30s): Extract diff & metadata
- **Phase 1** (3-5 min): **6 agents run simultaneously**
  - coding-standards — PSR-12 + framework patterns
  - linting — Type safety, dead code
  - functional-review — Business logic validation
  - test-coverage — Test quality
  - security — Injection, authz, secrets
  - pr-quality — PR metadata
- **Phase 1.5** (10s): Save all agent JSON outputs to `.review-tmp/`
- **Phase 2** (2 min): Verify all findings against diff
- **Phase 3-4** (1 min): Aggregate results & report

**Total: ~8 minutes** (vs ~25 min sequential)

### Key Behaviors

- **Diff-only scope**: Agents only report issues on `+` lines (changed/added code), never pre-existing code
- **Severity ceiling**: Formatting issues (whitespace, spacing) capped at `low` severity
- **Separate sections**: Report splits Issues, Suggestions, and Pre-existing Notes — only Issues affect risk score
- **Audit trail**: All agent JSON outputs saved to `.review-tmp/` for debugging and inspection

---

## What's Checked

### Coding Standards
- PSR-12 compliance
- Symfony/Laravel conventions (auto-detected)
- Type declarations & nullable types
- Visibility modifiers on all properties/methods

### Linting
- Type safety issues
- Unused imports & variables
- Dead code paths
- Code complexity

### Functional Review
- Business logic validation (against `project-constitution.md`)
- Architecture pattern enforcement
- Forbidden patterns detection

### Test Coverage
- Test presence for new/changed code
- Edge case coverage
- Test anti-patterns
- Framework detection (PHPUnit, Pest, Codeception)

### PR Quality
- Title conventions
- Description completeness
- Linked tickets/issues
- PR size warnings

### Security
- Injection risks (SQL, command, LDAP/NoSQL)
- Auth/authz gaps and IDOR
- Hard-coded secrets and unsafe deserialization

---

## Setup

### 1. Copy files (1 minute)

```bash
cp -r .github/ /path/to/your-project/
```

### 2. Create project constitution (optional, 5 minutes)

```bash
/generate-constitution
```

The `functional-review` agent uses this to validate business logic. It works without it, but with lower confidence.

### 3. Use slash commands

```bash
/pr-review 42              # Full review
/code-review               # Local changes
/code-review --quick       # Fast mode (skip slow agents)
/generate-constitution     # Auto-generate standards
```

---

## Framework Support

| Framework | Support | Requirements |
|-----------|---------|--------------|
| Symfony | 6.x+ | PHP 8.1+ |
| Laravel | 10+ | PHP 8.1+ |
| CakePHP | 3.x+ | PHP 7.2+ |
| Generic PHP | Full | PSR-12 only |

Auto-detected from `composer.json`. See [.github/instructions/](.github/instructions/) for framework-specific patterns.

---

## File Structure

```
.github/
├── agents/          <- 9 agents (1 orchestrator + 7 reviewers + 1 generator)
├── prompts/         <- Slash command definitions
└── instructions/    <- Framework-specific guides
```

---

## Prerequisites

| Feature | Needed | Token |
|---------|--------|-------|
| `/code-review` | Git + Copilot | No |
| `/pr-review --dry-run` | Git + Copilot | No |
| `/pr-review` (post to PR) | Git + Copilot + `GITHUB_TOKEN` | No |

No MCP server required. Works fully offline.

---

## Output

Each agent produces structured JSON with findings, confidence scores, and evidence. All agent outputs are saved to `.review-tmp/` for inspection. Results are aggregated into a risk-scored review (1-10 scale).

The report separates findings into distinct sections:
- **Critical / High / Medium / Low Issues** — actionable problems in changed code (affect risk score)
- **Suggestions** — alternative approaches, improvements (do not affect risk score)
- **Pre-existing Notes** — observations about unchanged code near the diff (do not affect risk score)

File references use backtick-wrapped full paths (e.g., `` `src/Controller/OrderController.php:L42` ``) to prevent broken auto-links in GitHub PR comments.

---

## Customization

Edit agent files directly to adjust:
- Severity thresholds
- Specific checks
- Framework patterns

See [.github/agents/](.github/agents/) and [.github/instructions/](.github/instructions/) for details.

---

## References

- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) — Commands, troubleshooting, setup
- [.github/agents/](.github/agents/) — Agent implementations
- [.github/instructions/](.github/instructions/) — Framework-specific patterns
- [.github/prompts/](.github/prompts/) — Slash command definitions

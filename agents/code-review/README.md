# Code Review Agent

Automated PR review system using parallel sub-agents. Designed for **PHP Symfony and Laravel** projects, model-agnostic (works with GPT-4o, Claude, Gemini, and others).

---

## How It Works

The agent runs a **4-phase review** when you invoke `/pr-review` on a pull request:

```
Phase 0: Context Extraction (~30s)
  Fetch PR diff, metadata, and project constitution

Phase 1: Parallel Agent Analysis (~2m)
  5 sub-agents run simultaneously:
  ├── coding-standards    PSR-12, Symfony/Laravel conventions
  ├── linting             Static analysis, type safety, dead code
  ├── functional-review   Business logic vs project constitution
  ├── test-coverage       Test quality, edge cases, anti-patterns
  └── pr-quality          PR description, linked tickets, size

Phase 2: Hallucination Detection (~1m)
  Verify all agent claims against actual code

Phase 3-4: Risk Scoring & Output (~1.5m)
  Aggregate findings, calculate risk score, post review
```

Total review time: **~5 minutes**

---

## Quick Start

### 1. Copy agent files to your PHP project

```bash
# From this directory
cp -r .github/ /path/to/your-php-project/.github/
```

### 2. (Optional) Create your project constitution

```bash
cp templates/project-constitution.example.md /path/to/your-php-project/project-constitution.md
# Edit with your project's business rules and patterns
```

The functional review agent uses this file to validate business logic. Without it, the agent still runs but with lower confidence.

### 3. Use in your workflow

**Review a PR:**
```
@workspace /pr-review <PR_NUMBER>
```

**Review local changes (no PR needed):**
```
@workspace /code-review              # all uncommitted changes
@workspace /code-review --staged     # staged changes only
@workspace /code-review --branch main  # changes since branching from main
```

**In GitHub PR comments:**
- Comment `@copilot /pr-review`

**Via GitHub Actions** (see [architecture docs](docs/architecture.md) for workflow YAML):
- Triggers automatically on PR creation

---

## Sub-Agents

| Agent | File | Model Tier | Purpose |
|-------|------|-----------|---------|
| **PR Quality** | `pr-quality.agent.md` | Light | PR title conventions, description quality, linked tickets, PR size, migration notes |
| **Linting** | `linting.agent.md` | Light | PHPStan/Psalm checks, unused imports, dead code, type safety |
| **Coding Standards** | `coding-standards.agent.md` | Medium | PSR-12 compliance, framework conventions. Auto-detects Symfony vs Laravel from `composer.json` |
| **Test Coverage** | `test-coverage.agent.md` | Medium | Test presence, quality, edge cases, anti-patterns (missing assertions, over-mocking) |
| **Functional Review** | `functional-review.agent.md` | Strong | Validates changes against project constitution (business rules, forbidden patterns, architecture decisions) |
| **Hallucination Detector** | `hallucination-detector.agent.md` | Strong | Phase 2 verification - ensures all findings from other agents are backed by real code evidence |

**Model tiers** optimize cost vs capability:
- **Light** (GPT-4o-mini, Haiku, Gemini Flash) - pattern matching, metadata checks
- **Medium** (GPT-4o, Sonnet, Gemini Pro) - framework analysis, test evaluation
- **Strong** (o1/o3-mini, Opus, Gemini Deep Think) - business logic reasoning, forensic verification

---

## Supported Frameworks

### Symfony (6.x+)
- Doctrine ORM patterns (N+1 detection, hydration, eager loading)
- Service container and dependency injection
- Security voters and `#[IsGranted]` attributes
- Form types, validation constraints, CSRF protection
- Event subscribers and domain events
- Bundle architecture and console commands

See: [Symfony setup guide](docs/symfony.md) | [Instructions file](.github/instructions/php-symfony.instructions.md)

### Laravel (10+)
- Eloquent ORM patterns (N+1 detection, eager loading, scopes)
- Middleware and authorization gates/policies
- Blade template security
- Queue jobs and event dispatching
- Migration safety (reversibility, indexes, foreign keys)
- Factory-based testing

See: [Laravel setup guide](docs/laravel.md) | [Instructions file](.github/instructions/php-laravel.instructions.md)

---

## Output Format

All agents produce structured JSON findings:

```json
{
  "metadata": {
    "agent": "coding-standards",
    "phase": 1,
    "pr_number": 42,
    "confidence": 85
  },
  "findings": {
    "issues": [
      {
        "severity": "high",
        "category": "dependency-injection",
        "title": "Service uses container injection",
        "description": "OrderService injects ContainerInterface instead of specific dependencies",
        "evidence": {
          "file": "src/Service/OrderService.php",
          "line_numbers": [12, 15],
          "code_snippet": "public function __construct(private ContainerInterface $container)"
        },
        "confidence": 90,
        "recommendation": "Inject specific services via constructor"
      }
    ],
    "summary": {
      "total_issues": 3,
      "critical_count": 0,
      "high_count": 1,
      "medium_count": 2,
      "overall_assessment": "Good code quality with minor DI improvements needed"
    }
  }
}
```

Risk scores are calculated on a 1-10 scale based on finding severity.

---

## Project Structure

```
agents/code-review/
├── README.md                                    # This file
├── .github/
│   ├── agents/
│   │   ├── coding-standards.agent.md            # PSR-12, Symfony/Laravel conventions
│   │   ├── linting.agent.md                     # Static analysis checks
│   │   ├── functional-review.agent.md           # Review against project constitution
│   │   ├── test-coverage.agent.md               # Test quality and coverage
│   │   ├── pr-quality.agent.md                  # PR description, tickets, context
│   │   └── hallucination-detector.agent.md      # Phase 2 verification
│   ├── prompts/
│   │   ├── pr-review.prompt.md                  # PR review orchestrator (needs GitHub)
│   │   └── code-review.prompt.md                # Local code review (works offline)
│   └── instructions/
│       ├── php-symfony.instructions.md           # Symfony coding standards context
│       └── php-laravel.instructions.md           # Laravel coding standards context
├── docs/
│   ├── architecture.md                          # 4-phase system architecture
│   ├── symfony.md                               # Symfony setup & usage guide
│   └── laravel.md                               # Laravel setup & usage guide
└── templates/
    └── project-constitution.example.md          # Template for project-specific rules
```

---

## Prerequisites

| Command | Requires | GitHub MCP | API Token |
|---------|----------|-----------|-----------|
| `/code-review` | Git repo + VS Code + Copilot | No | No |
| `/pr-review --dry-run` | Git repo + VS Code + Copilot | No | No |
| `/pr-review` (post comment) | Git repo + VS Code + Copilot | No | `GITHUB_TOKEN` for posting |
| GitHub Actions (auto-trigger) | GitHub Actions workflow | No | Auto-provided `GITHUB_TOKEN` |

**No MCP server setup is required.** Copilot's built-in workspace access and GitHub integration handle file reading and PR operations natively.

**Optional:** If Copilot struggles with PR fetching in your environment, you can add the [GitHub MCP server](https://github.com/modelcontextprotocol/servers/tree/main/src/github) for more reliable PR access. See [architecture docs](docs/architecture.md) for setup.

---

## Configuration

### Framework Detection

The coding-standards agent auto-detects your framework by checking `composer.json`:

- `symfony/framework-bundle` -> Symfony mode
- `laravel/framework` -> Laravel mode
- Both present -> reviews against both standards
- Neither found -> generic PHP/PSR-12 only

### Customizing Agents

Each agent is a standalone markdown file. To customize:

1. Edit the `.agent.md` file directly
2. Adjust severity levels, confidence thresholds, or checks
3. Add project-specific patterns to the instructions files

### Token Budget

Each agent is designed to stay under **8,000 tokens** to work across different LLM providers. If you add custom checks, monitor token usage.

---

## Architecture Deep Dive

For full details on the 4-phase architecture, agent output protocol, abort conditions, risk scoring formula, and GitHub Actions integration, see [docs/architecture.md](docs/architecture.md).

---
name: code-review
description: "Reviews local code changes (staged or unstaged) using the same multi-agent system as pr-review, but without requiring a PR or GitHub access."
---

# Code Review - Local Changes

Review local code changes using the parallel agent system. This works on your current git diff without needing a PR or GitHub access.

## Usage

```
/code-review
/code-review --staged
/code-review --branch main
/code-review --files src/Service/OrderService.php src/Controller/OrderController.php
/code-review --quick
```

- **Default**: Review all uncommitted changes (staged + unstaged)
- **--staged**: Review only staged changes (`git diff --cached`)
- **--branch <base>**: Review all changes since branching from `<base>` (`git diff <base>...HEAD`)
- **--files <paths>**: Review specific files only
- **--quick**: Coding standards + linting only (faster)

## Prerequisites

- A git repository with changes to review
- No GitHub access, MCP, or API tokens required
- Works fully offline in VS Code with Copilot

## Execution Protocol

### Phase 0: Context Extraction

1. **Get the diff based on mode:**
   - Default: `git diff` + `git diff --cached` (all uncommitted changes)
   - `--staged`: `git diff --cached` (staged only)
   - `--branch main`: `git diff main...HEAD` (branch changes)
   - `--files`: `git diff -- <file1> <file2>` (specific files)

2. **Extract context:**
   - Files changed with line counts
   - Detect framework from `composer.json` (Symfony vs Laravel)
   - Check for `project-constitution.md` in repo root
   - Current branch name

3. **Abort conditions:**
   - No changes found -> abort with message
   - Not a git repository -> abort

### Phase 1: Parallel Agent Analysis

Launch these agents (same as pr-review, minus pr-quality since there's no PR metadata):

| Agent | Model Tier | Focus |
|-------|-----------|-------|
| linting | Light | Type safety, unused code, complexity |
| coding-standards | Medium | PSR-12, framework conventions |
| test-coverage | Medium | Test quality and gaps |
| functional-review | Strong | Business logic vs constitution |

**Note:** The `pr-quality` agent is skipped since there is no PR title/description to evaluate.

**Quick review (2 agents):**
- coding-standards
- linting

### Phase 2: Hallucination Detection

Same as pr-review - verify all findings against the actual diff.

### Phase 3-4: Risk Scoring & Output

Same risk scoring formula as pr-review. Output is printed to console (no GitHub posting).

**Output format:**

```markdown
## Code Review - Local Changes

**Risk Score: X/10**
**Review Confidence: XX%**
**Diff source:** [uncommitted / staged / branch:main / files:...]

### Critical Issues (N)
- [ ] [Issue title] ([file:line])

### High Issues (N)
- [ ] [Issue title] ([file:line])

### Medium Issues (N)
- [ ] [Issue title] ([file:line])

### Suggestions (N)
- [Issue title] ([file:line])

---

**Agents:** coding-standards | linting | functional-review | test-coverage
**Framework:** [Symfony/Laravel/Generic PHP]
**Constitution:** [Found/Not found]
```

## Tips

- Run `/code-review --staged` before committing to catch issues early
- Run `/code-review --branch main` before opening a PR
- Use `/code-review --quick` for fast style-only feedback
- For full PR review with metadata checks, use `/pr-review` instead

---
name: pr-review
description: "Orchestrates a parallel multi-agent PR review for PHP projects. Analyzes coding standards, linting, functional correctness, test coverage, and PR quality, then verifies findings and produces a risk-scored review."
---

# PR Review - Multi-Agent Orchestrator

Review PR `$PR_NUMBER` using the parallel agent system described below.

## Usage

```
/pr-review <PR_NUMBER>
/pr-review <PR_NUMBER> --dry-run
/pr-review <PR_NUMBER> --quick
```

- **Default**: Full review, posts comment to GitHub
- **--dry-run**: Full review, saves locally only
- **--quick**: Coding standards + linting only (faster)

## Execution Protocol

### Phase 0: Context Extraction (~30 seconds)

1. **Validate PR exists:**
   ```bash
   gh pr view $PR_NUMBER --json title,body,files,additions,deletions
   ```
   If PR doesn't exist or diff is empty -> abort immediately.

2. **Fetch PR diff:**
   ```bash
   gh pr diff $PR_NUMBER
   ```

3. **Extract context:**
   - PR title and description
   - Files changed with line counts
   - Detect framework from `composer.json` (Symfony vs Laravel)
   - Check for `project-constitution.md` in repo root

4. **Abort conditions:**
   - PR not found -> abort with error message
   - Empty diff -> abort (nothing to review)
   - Cannot fetch metadata -> abort

### Phase 1: Parallel Agent Analysis (~2 minutes)

Launch ALL agents simultaneously. Each agent receives the PR diff and metadata.

**Standard review (5 agents):**

| Agent | File | Model Tier | Focus |
|-------|------|-----------|-------|
| pr-quality | `.github/agents/pr-quality.agent.md` | Light | PR metadata and documentation |
| linting | `.github/agents/linting.agent.md` | Light | Type safety, unused code, complexity |
| coding-standards | `.github/agents/coding-standards.agent.md` | Medium | PSR-12, framework conventions |
| test-coverage | `.github/agents/test-coverage.agent.md` | Medium | Test quality and gaps |
| functional-review | `.github/agents/functional-review.agent.md` | Strong | Business logic vs constitution |

**Model tier examples:**
- **Light**: GPT-4o-mini, Claude Haiku, Gemini Flash (pattern matching, metadata checks)
- **Medium**: GPT-4o, Claude Sonnet, Gemini Pro (framework analysis, test evaluation)
- **Strong**: o1/o3-mini, Claude Opus, Gemini Deep Think (business logic reasoning, verification)

**Quick review (2 agents):**
- coding-standards
- linting

Each agent MUST:
- Write findings as structured JSON
- Include confidence score (0-100)
- Provide evidence for every claim (file, line, code snippet)
- Respect abort conditions (return low confidence when analysis not applicable)

### Phase 2: Hallucination Detection (~1 minute)

After all Phase 1 agents complete, run the hallucination detector:

**Agent:** `.github/agents/hallucination-detector.agent.md`

**Input:** All Phase 1 agent outputs + original PR diff

**Verification process:**
1. For each agent's findings, verify every claim against the actual diff
2. Check that quoted code exists verbatim in the diff
3. Check that referenced line numbers contain the claimed content
4. Check that file paths exist in the PR

**Abort condition:** If ANY hallucination is detected, abort the entire review. Do not post a partial review.

### Phase 3: Risk Score Calculation (~30 seconds)

Aggregate verified findings into a risk score (1-10):

```
If critical > 0:           risk_score = 10
Else if high >= 3:         risk_score = 9
Else if high == 2:         risk_score = 8
Else if high == 1:         risk_score = 7
Else if medium >= 5:       risk_score = 6
Else if medium >= 3:       risk_score = 5
Else if medium > 0:        risk_score = 4
Else if low > 0:           risk_score = 3
Else:                      risk_score = 1
```

Calculate review confidence:
```
review_confidence = average of all agent confidence scores
```

### Phase 4: Output Generation (~1 minute)

**Format the review as a GitHub PR comment:**

```markdown
## PR Review - #$PR_NUMBER

**Risk Score: X/10** [icon based on score]
**Review Confidence: XX%**

### Critical Issues (N)
- [ ] [Issue title] ([file:line])

### High Issues (N)
- [ ] [Issue title] ([file:line])

### Medium Issues (N)
- [ ] [Issue title] ([file:line])

### Suggestions (N)
- [Issue title] ([file:line])

---

**Agents:** coding-standards | linting | functional-review | test-coverage | pr-quality
**Framework:** [Symfony/Laravel/Generic PHP]
**Constitution:** [Found/Not found]
```

**Risk score icons:**
- 1-3: Low risk
- 4-6: Medium risk
- 7-8: High risk
- 9-10: Critical risk

**Posting:**
- Default: Post as PR comment via `gh pr comment`
- `--dry-run`: Print to console only

## Abort Conditions (Non-Negotiable)

| Condition | Phase | Action |
|-----------|-------|--------|
| PR not found | 0 | Abort immediately |
| Empty diff | 0 | Abort immediately |
| Agent fails to produce output | 1 | Skip agent, note in report |
| Hallucinations found | 2 | Abort entire review |
| All agents return 0% confidence | 1 | Abort - nothing to review |

When aborting, output:
```markdown
## PR Review - ABORTED

**Reason:** [specific reason]
**Phase:** [where it failed]
**PR:** #$PR_NUMBER

Cannot proceed with partial review. No findings posted.
```

## Agent Output Contract

All agents MUST return JSON matching this structure:

```json
{
  "metadata": {
    "agent": "<agent-name>",
    "phase": 1,
    "pr_number": "$PR_NUMBER",
    "timestamp_start": "<ISO-8601>",
    "timestamp_end": "<ISO-8601>",
    "confidence": 85
  },
  "findings": {
    "issues": [
      {
        "severity": "critical|high|medium|low",
        "category": "<issue-type>",
        "title": "<one-line>",
        "description": "<detailed>",
        "evidence": {
          "file": "<path>",
          "line_numbers": [10, 15],
          "code_snippet": "<exact code>"
        },
        "confidence": 90,
        "recommendation": "<fix>"
      }
    ],
    "summary": {
      "total_issues": 5,
      "critical_count": 0,
      "high_count": 1,
      "medium_count": 3,
      "low_count": 1,
      "overall_assessment": "<summary>"
    }
  }
}
```

## Tips

- Start with `--dry-run` to test before posting to GitHub
- Use `--quick` for fast feedback on style issues
- Create a `project-constitution.md` to get maximum value from the functional review agent
- If agents time out, the PR may be too large - consider splitting

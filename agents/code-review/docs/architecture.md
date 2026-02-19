# Code Review Agent - Architecture

This document describes the 4-phase architecture of the PR review system, the agent output protocol, risk scoring formula, and GitHub Actions integration.

---

## System Overview

The system uses **orchestrated agent parallelism** to reduce review time from hours to minutes:

```
Input (PR)
  |
Phase 0: Extract context (30 seconds)
  |-- Fetch PR metadata + diff
  |-- Detect framework (Symfony/Laravel)
  |-- Load project constitution (if exists)
  |
Phase 1: Parallel agent analysis (2 minutes)
  |-- coding-standards     PSR-12 + framework conventions
  |-- linting              Static analysis, type safety
  |-- functional-review    Business logic vs constitution
  |-- test-coverage        Test quality and gaps
  |-- pr-quality           PR metadata and documentation
  |
Phase 2: Verification (1 minute)
  |-- hallucination-detector (verify all findings)
  |
Phase 3: Risk scoring (30 seconds)
  |-- Aggregate findings by severity
  |-- Calculate risk score (1-10)
  |
Phase 4: Output generation (1 minute)
  |-- Format findings as GitHub PR comment
  |-- Post or save locally (--dry-run)
```

**Total runtime: ~5 minutes** (vs. 30-60 minutes manual review)

---

## Phase Details

### Phase 0: Context Extraction

**Goal:** Gather everything agents need before they start.

**Steps:**
1. Validate PR exists via `gh pr view`
2. Fetch complete diff via `gh pr diff`
3. Extract PR metadata (title, description, files changed, additions/deletions)
4. Detect framework from `composer.json`:
   - `symfony/framework-bundle` -> Symfony mode
   - `laravel/framework` -> Laravel mode
5. Check for `project-constitution.md` in repo root
6. Prepare structured context for agents

**Abort conditions:**
- PR doesn't exist
- Diff is empty
- Cannot fetch metadata

### Phase 1: Parallel Agent Analysis

**Goal:** Run all analysis agents simultaneously for maximum speed.

All 5 agents launch at the same time. Each receives:
- Complete PR diff
- PR metadata (title, description, branch info)
- Framework detection result
- Project constitution path (if found)

**Agent responsibilities:**

| Agent | Primary Focus | Abort When |
|-------|--------------|------------|
| coding-standards | PSR-12, framework patterns | No PHP code in diff |
| linting | Type safety, unused code, complexity | No PHP code in diff |
| functional-review | Business logic vs constitution | Never (reduces confidence if no constitution) |
| test-coverage | Test quality, gaps, anti-patterns | No test code in diff |
| pr-quality | PR title, description, tickets, size | No PR metadata |

Each agent writes structured JSON output independently.

### Phase 2: Hallucination Detection

**Goal:** Verify every claim from Phase 1 is backed by real evidence.

The hallucination detector:
1. Reads ALL Phase 1 agent outputs
2. For each finding, searches the actual PR diff for the quoted evidence
3. Verifies line numbers match real content
4. Verifies file paths exist in the PR
5. Classifies each claim: VERIFIED, HALLUCINATED, UNVERIFIABLE, SPECULATION

**Abort condition:** If ANY hallucination is detected, the entire review is aborted. No partial reviews are posted.

### Phase 3: Risk Scoring

**Formula:**

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

Review confidence is the average of all agent confidence scores, capped at 100.

### Phase 4: Output Generation

Findings are aggregated into a GitHub PR comment:

```markdown
## PR Review - #42

**Risk Score: 7/10**
**Review Confidence: 85%**

### Critical Issues (0)
(none)

### High Issues (1)
- [ ] Service uses container injection (src/Service/OrderService.php:12)

### Medium Issues (3)
- [ ] Missing return type on public method (src/Controller/OrderController.php:45)
- [ ] Test without assertions (tests/Unit/OrderTest.php:23)
- [ ] PR description missing "why" context

### Suggestions (1)
- Consider splitting PR (350 lines changed)

---
Agents: coding-standards | linting | functional-review | test-coverage | pr-quality
Framework: Symfony | Constitution: Found
```

---

## Agent Output Contract

All agents MUST return JSON matching this structure:

```json
{
  "metadata": {
    "agent": "<agent-name>",
    "phase": 1,
    "pr_number": 42,
    "timestamp_start": "2025-02-18T14:32:00Z",
    "timestamp_end": "2025-02-18T14:33:45Z",
    "confidence": 85
  },
  "findings": {
    "issues": [
      {
        "severity": "critical|high|medium|low",
        "category": "<issue-type>",
        "title": "<one-line summary>",
        "description": "<detailed explanation>",
        "evidence": {
          "file": "src/Service/OrderService.php",
          "line_numbers": [12, 15],
          "code_snippet": "public function __construct(private ContainerInterface $container)"
        },
        "confidence": 90,
        "recommendation": "<how to fix>"
      }
    ],
    "summary": {
      "total_issues": 5,
      "critical_count": 0,
      "high_count": 1,
      "medium_count": 3,
      "low_count": 1,
      "overall_assessment": "<one paragraph summary>"
    }
  }
}
```

### Confidence Scoring

**Overall confidence (0-100):**
- 90-100: High confidence, clear evidence for all findings
- 70-89: Good confidence, most findings well-supported
- 50-69: Moderate, some uncertainty
- 30-49: Low, significant limitations
- 0-29: Very low, cannot reliably analyze

**Per-finding confidence (0-100):**
- 100: Definitive issue - code clearly violates principle
- 80-99: Very likely - strong evidence
- 60-79: Probable - reasonable concern
- 40-59: Possible - alternative explanations exist
- 0-39: Uncertain - weak evidence

---

## Abort Conditions

| Condition | Phase | Action |
|-----------|-------|--------|
| PR not found | 0 | Abort immediately |
| Empty diff | 0 | Abort immediately |
| Agent fails to produce output | 1 | Skip agent, note in report |
| All agents return 0% confidence | 1 | Abort - nothing to review |
| Hallucinations found | 2 | Abort entire review |

When aborting:
```markdown
## PR Review - ABORTED

**Reason:** Phase 2 - Hallucinations detected
**PR:** #42
**Timestamp:** 2025-02-18T14:35:22Z

Cannot proceed with partial review. No findings posted.
```

---

## GitHub Actions Integration

To run the review automatically on every PR:

```yaml
# .github/workflows/pr-review.yml

name: AI PR Review

on:
  pull_request:
    branches: [main, develop]
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write
      contents: read

    steps:
      - uses: actions/checkout@v4

      - name: Set up PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'

      - name: Install dependencies
        run: composer install --no-interaction --prefer-dist

      - name: Run PR Review
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR_NUMBER: ${{ github.event.pull_request.number }}
        run: |
          # Option 1: Via Copilot Coding Agent (if enabled)
          # The agents in .github/agents/ are auto-discovered

          # Option 2: Via GitHub CLI
          gh copilot suggest "Run /pr-review $PR_NUMBER"

          # Option 3: Direct script invocation
          # python scripts/orchestrate.py $PR_NUMBER
```

### Required Permissions

- `pull-requests: write` - to post review comments
- `contents: read` - to read PR diff and repository files
- `GITHUB_TOKEN` - automatically provided in Actions

---

## Adding Custom Agents

To add a new analysis agent:

1. Create `.github/agents/your-agent.agent.md` following the output contract above
2. Add the agent to Phase 1 in `pr-review.prompt.md`
3. Update the hallucination detector's expected agent list
4. Test independently with `--dry-run` on 3-5 sample PRs
5. Calibrate confidence scoring after initial runs

### Agent Design Rules

- One analysis dimension per agent (single responsibility)
- Stay under 8,000 tokens to support all LLM providers
- Every claim must have evidence (file, line, code snippet)
- Include abort conditions for when analysis isn't applicable
- Confidence scores must be calibrated (not always 90+)

---

## Debugging

### Agent produces no output
- Check if abort conditions triggered (diff has no relevant code)
- Review agent's confidence - may have returned 0%

### Low confidence scores
- Review the agent's output for limitations noted
- Check if the PR is too small for meaningful analysis

### Hallucination detector aborting
- Read detector output for specific failed verifications
- Common cause: agent quoted code that was paraphrased, not verbatim
- Fix: improve agent instructions to require exact quotes

### False positives
- Increase confidence threshold for posting findings
- Refine agent prompts to be more specific
- Add exclusion patterns for known acceptable code

### Review taking too long
- PR may be too large - recommend splitting
- Check individual agent timing in metadata timestamps
- Use `--quick` mode for faster feedback

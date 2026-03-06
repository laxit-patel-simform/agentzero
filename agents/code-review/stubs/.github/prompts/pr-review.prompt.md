---
name: pr-review
description: "Orchestrates a parallel multi-agent PR review for PHP projects."
agent: code-review-orchestrator
---

# PR Review - Multi-Agent

Review PR `$PR_NUMBER` using the parallel agent system.

## Usage

```
/pr-review <PR_NUMBER>                # Full review, posts comment to PR
/pr-review <PR_NUMBER> --dry-run      # Local only, no PR comment
/pr-review <PR_NUMBER> --quick        # Coding standards + linting only
```

## Execution Protocol

**Execute all phases automatically without pausing for user input.**

### Phase 0: Context Extraction

**The orchestrator checks authentication as a prerequisite before this phase. If auth fails, it handles login — you will not reach this phase without valid auth.**

**Run ONE terminal command. Do NOT read source files. Move to Phase 1 immediately.**

**GitHub:**
```bash
REVIEW_DIR=.review-tmp/pr-review/$PR_NUMBER && mkdir -p "$REVIEW_DIR" \
	&& gh pr view $PR_NUMBER --json title,body,files,additions,deletions > "$REVIEW_DIR/metadata.json" \
	&& gh pr diff $PR_NUMBER > "$REVIEW_DIR/diff.txt"
```

**Bitbucket** (if remote URL contains `bitbucket.org`):
```bash
REVIEW_DIR=.review-tmp/pr-review/$PR_NUMBER && mkdir -p "$REVIEW_DIR" \
	&& REMOTE=$(git remote get-url origin) \
	&& WORKSPACE=$(echo "$REMOTE" | sed 's|.*bitbucket.org[:/]\([^/]*\)/.*|\1|') \
	&& REPO=$(echo "$REMOTE" | sed 's|.*bitbucket.org[:/][^/]*/\([^/.]*\).*|\1|') \
	&& curl -s -H "Authorization: Bearer $BITBUCKET_TOKEN" \
		"https://api.bitbucket.org/2.0/repositories/$WORKSPACE/$REPO/pullrequests/$PR_NUMBER" > "$REVIEW_DIR/metadata.json" \
	&& curl -s -H "Authorization: Bearer $BITBUCKET_TOKEN" \
		"https://api.bitbucket.org/2.0/repositories/$WORKSPACE/$REPO/pullrequests/$PR_NUMBER/diff" > "$REVIEW_DIR/diff.txt"
```

Search for `project-constitution.md` (repo root, `docs/`, `.github/`). Abort only if: PR not found or empty diff.

### Phase 1: Parallel Agent Analysis

**Standard: 6 agents in parallel.** **Quick: 2 agents** (coding-standards + linting).

Pass `$REVIEW_DIR/diff.txt` path to each agent. Agents return their JSON responses to the orchestrator. Pass `$REVIEW_DIR/metadata.json` path only to `pr-quality`.

### Phase 1.5: Save Agent Outputs

After all agents return, the orchestrator saves each agent's JSON response to `$REVIEW_DIR/<agent-name>.json` using a single `runInTerminal` command. This creates the audit trail for debugging and the hallucination detector to read from.

### Phase 2: Hallucination Detection

Pass `$REVIEW_DIR` path to hallucination-detector. It reads all agent JSON files from `$REVIEW_DIR/` and cross-references against the diff. It verifies that all claims reference `+` lines only. Abort if hallucinations found.

### Phase 3-4: Risk Scoring & Output

**Scoring excludes:** pre-existing issues, style/formatting issues, and suggestions.

Risk score (1-10): critical>0 → 10 | high≥3 → 9 | high=2 → 8 | high=1 → 7 | medium≥5 → 6 | medium≥3 → 5 | medium>0 → 4 | low>0 → 3 | else → 1

**Post to PR** via `gh pr comment $PR_NUMBER --body "<review>"` (GitHub) or Bitbucket API. `--dry-run` → print to console only.

**File reference format:** Use full repo-relative paths wrapped in backticks to prevent broken GitHub auto-links. Example: `` `html/src/Controller/DashboardController.php:L123` ``

```markdown
## PR Review - #$PR_NUMBER

**Risk Score: X/10**
**Review Confidence: XX%**
**Context:** [Full / Partial / Minimal]

### Critical / High Issues (N)
- [ ] [Issue title] (`full/path/to/file.php:L123`)

### Medium Issues (N)
- [ ] [Issue title] (`full/path/to/file.php:L123`)

### Low Issues (N)
- [Issue title] (`full/path/to/file.php:L123`)

### Suggestions (N)
- [Suggestion title] (`full/path/to/file.php:L123`) — [rationale]

### Pre-existing Notes (N)
> These are observations about unchanged code near the diff. They do not affect the risk score.
- [Note title] (`full/path/to/file.php:L123`)

---
**Agents:** [list] | **Framework:** [detected] | **Constitution:** [found/not found]
**Tooling:** PHPStan [level] | Psalm [equivalent] (from linting agent, if provided)
```

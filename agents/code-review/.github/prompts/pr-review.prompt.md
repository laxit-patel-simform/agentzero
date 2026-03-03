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

**Run ONE terminal command. Do NOT read source files. Move to Phase 1 immediately.**

**GitHub (default) — with automatic fallback:**
```bash
REVIEW_DIR=.review-tmp/pr-review/$PR_NUMBER && mkdir -p "$REVIEW_DIR" \
	&& { gh pr view $PR_NUMBER --json title,body,files,additions,deletions > "$REVIEW_DIR/metadata.json" \
	&& gh pr diff $PR_NUMBER > "$REVIEW_DIR/diff.txt"; } 2>/dev/null \
	|| { echo "GH_FALLBACK: gh CLI not authenticated, using git fetch" \
	&& git fetch origin "pull/$PR_NUMBER/head:_pr_review_$PR_NUMBER" 2>/dev/null \
	&& git diff "origin/$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo main)..._pr_review_$PR_NUMBER" > "$REVIEW_DIR/diff.txt" \
	&& echo '{"note":"metadata unavailable - used git fallback"}' > "$REVIEW_DIR/metadata.json"; }
```

**If the output contains `GH_FALLBACK`:**
- The diff was fetched via `git fetch` — the review can proceed normally
- PR metadata (title, description) is unavailable — **skip the `pr-quality` agent** (run 5 agents instead of 6)
- Do NOT ask the user to paste the diff or authenticate — just proceed
- Note in the final report: "PR metadata unavailable (gh CLI not authenticated). Skipped pr-quality agent."

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

**Abort only if:** both `gh` and `git fetch` fail, empty diff, or PR not found. Search for `project-constitution.md` (repo root, `docs/`, `.github/`).

### Phase 1: Parallel Agent Analysis

**Standard: 6 agents in parallel** (or 5 if metadata unavailable — skip pr-quality). **Quick: 2 agents** (coding-standards + linting).

Pass `$REVIEW_DIR/diff.txt` to each agent — they will load it with `readFile`. Pass `$REVIEW_DIR/metadata.json` only to `pr-quality`. Do NOT save agent responses to files.

### Phase 2: Hallucination Detection

Pass all agent JSON responses directly inline to hallucination-detector (along with the diff file path). Do NOT run terminal commands to save intermediate files. Abort if hallucinations found.

### Phase 3-4: Risk Scoring & Output

Risk score (1-10): critical>0 → 10 | high≥3 → 9 | high=2 → 8 | high=1 → 7 | medium≥5 → 6 | medium≥3 → 5 | medium>0 → 4 | low>0 → 3 | else → 1

**Post to PR** via `gh pr comment $PR_NUMBER --body "<review>"` (or Bitbucket API). `--dry-run` or `GH_FALLBACK` → prints to console only.

```markdown
## PR Review - #$PR_NUMBER

**Risk Score: X/10**
**Review Confidence: XX%**
**Context:** [Full / Partial / Minimal]

### Critical Issues (N)
- [ ] [Issue title] ([file:line])

### High / Medium Issues (N)
- [ ] [Issue title] ([file:line])

### Suggestions (N)
- [Issue title] ([file:line])

---
**Agents:** [list] | **Framework:** [detected] | **Constitution:** [found/not found]
**Tooling:** PHPStan [level] | Psalm [equivalent] (from linting agent, if provided)
```

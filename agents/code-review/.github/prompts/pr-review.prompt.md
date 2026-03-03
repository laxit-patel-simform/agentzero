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

**First, detect the remote platform (GitHub or Bitbucket) from `git remote get-url origin`. Then run ONE terminal command to fetch the diff. Do NOT read source files. Move to Phase 1 immediately after.**

**GitHub — with automatic fallback:**
```bash
REVIEW_DIR=.review-tmp/pr-review/$PR_NUMBER && mkdir -p "$REVIEW_DIR" \
	&& if gh auth status &>/dev/null; then \
		gh pr view $PR_NUMBER --json title,body,files,additions,deletions > "$REVIEW_DIR/metadata.json" \
		&& gh pr diff $PR_NUMBER > "$REVIEW_DIR/diff.txt" \
		&& echo "MODE=gh_full"; \
	else \
		echo "WARNING: gh CLI not authenticated. To enable full reviews with PR metadata, run:" \
		&& echo "  gh auth login" \
		&& echo "Continuing with git fallback..." \
		&& git fetch origin "pull/$PR_NUMBER/head:_pr_review_$PR_NUMBER" \
		&& git diff "origin/$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo main)..._pr_review_$PR_NUMBER" > "$REVIEW_DIR/diff.txt" \
		&& echo '{}' > "$REVIEW_DIR/metadata.json" \
		&& echo "MODE=gh_fallback"; \
	fi
```

**Bitbucket — with automatic fallback:**
```bash
REVIEW_DIR=.review-tmp/pr-review/$PR_NUMBER && mkdir -p "$REVIEW_DIR" \
	&& REMOTE=$(git remote get-url origin) \
	&& WORKSPACE=$(echo "$REMOTE" | sed 's|.*bitbucket.org[:/]\([^/]*\)/.*|\1|') \
	&& REPO=$(echo "$REMOTE" | sed 's|.*bitbucket.org[:/][^/]*/\([^/.]*\).*|\1|') \
	&& if [ -n "$BITBUCKET_TOKEN" ]; then \
		curl -s -H "Authorization: Bearer $BITBUCKET_TOKEN" \
			"https://api.bitbucket.org/2.0/repositories/$WORKSPACE/$REPO/pullrequests/$PR_NUMBER" > "$REVIEW_DIR/metadata.json" \
		&& curl -s -H "Authorization: Bearer $BITBUCKET_TOKEN" \
			"https://api.bitbucket.org/2.0/repositories/$WORKSPACE/$REPO/pullrequests/$PR_NUMBER/diff" > "$REVIEW_DIR/diff.txt" \
		&& echo "MODE=bb_full"; \
	else \
		echo "WARNING: BITBUCKET_TOKEN not set. To enable full reviews with PR metadata:" \
		&& echo "  1. Create an App Password: https://bitbucket.org/account/settings/app-passwords/" \
		&& echo "     (grant: Repositories Read, Pull Requests Read)" \
		&& echo "  2. Export it: export BITBUCKET_TOKEN=your_app_password" \
		&& echo "Continuing with git fallback..." \
		&& PR_BRANCH=$(curl -s "https://api.bitbucket.org/2.0/repositories/$WORKSPACE/$REPO/pullrequests/$PR_NUMBER" 2>/dev/null | grep -o '"source":{[^}]*"branch":{[^}]*"name":"[^"]*"' | grep -o '"name":"[^"]*"$' | cut -d'"' -f4) \
		&& if [ -n "$PR_BRANCH" ]; then \
			git fetch origin "$PR_BRANCH" \
			&& git diff "origin/$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo main)...origin/$PR_BRANCH" > "$REVIEW_DIR/diff.txt" \
			&& echo '{}' > "$REVIEW_DIR/metadata.json" \
			&& echo "MODE=bb_fallback"; \
		else \
			echo "ERROR: Could not fetch PR branch. Public API access may be restricted." \
			&& echo "Set BITBUCKET_TOKEN to proceed." \
			&& echo "MODE=bb_failed"; \
		fi; \
	fi
```

### Phase 0 — Handling the result

| Mode | Diff | Metadata | pr-quality agent | Can post to PR |
|------|------|----------|-----------------|----------------|
| `gh_full` | Yes | Yes | Yes (6 agents) | Yes |
| `gh_fallback` | Yes | No | Skip (5 agents) | No — print to console |
| `bb_full` | Yes | Yes | Yes (6 agents) | Yes |
| `bb_fallback` | Yes | No | Skip (5 agents) | No — print to console |
| `bb_failed` | No | No | **Abort review** | No |

- **Always proceed automatically** — do NOT ask the user to paste the diff or authenticate
- The auth warning is already printed in the terminal output — the user sees it
- Search for `project-constitution.md` (repo root, `docs/`, `.github/`)

### Phase 1: Parallel Agent Analysis

**Full mode: 6 agents in parallel.** **Fallback mode: 5 agents** (skip pr-quality). **Quick: 2 agents** (coding-standards + linting).

Pass `$REVIEW_DIR/diff.txt` to each agent — they will load it with `readFile`. Pass `$REVIEW_DIR/metadata.json` only to `pr-quality`. Do NOT save agent responses to files.

### Phase 2: Hallucination Detection

Pass all agent JSON responses directly inline to hallucination-detector (along with the diff file path). Do NOT run terminal commands to save intermediate files. Abort if hallucinations found.

### Phase 3-4: Risk Scoring & Output

Risk score (1-10): critical>0 → 10 | high≥3 → 9 | high=2 → 8 | high=1 → 7 | medium≥5 → 6 | medium≥3 → 5 | medium>0 → 4 | low>0 → 3 | else → 1

**Post to PR** via `gh pr comment` (GitHub) or Bitbucket API — only in `*_full` modes. In `*_fallback` or `--dry-run` → print to console only.

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

In fallback mode, append to the report:
> **Note:** PR metadata unavailable — `pr-quality` agent was skipped. To enable full reviews: run `gh auth login` (GitHub) or `export BITBUCKET_TOKEN=<token>` (Bitbucket).

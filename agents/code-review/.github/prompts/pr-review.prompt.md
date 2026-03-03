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

**First, detect the remote platform (GitHub or Bitbucket) from `git remote get-url origin`. Then run ONE terminal command to check auth and fetch the diff. Do NOT read source files.**

**GitHub:**
```bash
REVIEW_DIR=.review-tmp/pr-review/$PR_NUMBER && mkdir -p "$REVIEW_DIR" \
	&& if gh auth status &>/dev/null; then \
		gh pr view $PR_NUMBER --json title,body,files,additions,deletions > "$REVIEW_DIR/metadata.json" \
		&& gh pr diff $PR_NUMBER > "$REVIEW_DIR/diff.txt" \
		&& echo "AUTH=ok"; \
	else \
		echo "AUTH=failed"; \
	fi
```

**Bitbucket** (if remote URL contains `bitbucket.org`):
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
		&& echo "AUTH=ok"; \
	else \
		echo "AUTH=failed"; \
	fi
```

### Phase 0 — Auth Failed: run authentication for the user

**If the output contains `AUTH=failed`, do NOT proceed to Phase 1.** Instead, run the authentication command directly in the terminal:

**GitHub — run this in terminal:**
```bash
gh auth login --web -h github.com
```

**Bitbucket — run this in terminal:**
```bash
echo "Bitbucket authentication required." \
	&& echo "1. Open: https://bitbucket.org/account/settings/app-passwords/" \
	&& echo "2. Create an App Password (Repositories: Read, Pull Requests: Read)" \
	&& echo "3. Then run: export BITBUCKET_TOKEN=your_app_password"
```

After running the auth command, tell the user:
> Authentication started. Follow the prompts in the terminal to complete login, then re-run `/pr-review $PR_NUMBER`.

**STOP after this. Do not proceed to Phase 1.**

### Phase 0 — Auth OK: proceed immediately

Search for `project-constitution.md` (repo root, `docs/`, `.github/`). Abort only if: PR not found or empty diff. Move to Phase 1 immediately.

### Phase 1: Parallel Agent Analysis

**Standard: 6 agents in parallel.** **Quick: 2 agents** (coding-standards + linting).

Pass `$REVIEW_DIR/diff.txt` to each agent — they will load it with `readFile`. Pass `$REVIEW_DIR/metadata.json` only to `pr-quality`. Do NOT save agent responses to files.

### Phase 2: Hallucination Detection

Pass all agent JSON responses directly inline to hallucination-detector (along with the diff file path). Do NOT run terminal commands to save intermediate files. Abort if hallucinations found.

### Phase 3-4: Risk Scoring & Output

Risk score (1-10): critical>0 → 10 | high≥3 → 9 | high=2 → 8 | high=1 → 7 | medium≥5 → 6 | medium≥3 → 5 | medium>0 → 4 | low>0 → 3 | else → 1

**Post to PR** via `gh pr comment $PR_NUMBER --body "<review>"` (GitHub) or Bitbucket API. `--dry-run` → print to console only.

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

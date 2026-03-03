---
name: code-review
description: "Reviews local code changes using the parallel multi-agent system without requiring a PR."
agent: code-review-orchestrator
---

# Code Review - Local Changes

Review local code changes using the parallel agent system. Works on your current git diff without needing a PR or remote access.

## Usage

```
/code-review                                    # All uncommitted changes
/code-review --staged                           # Staged changes only
/code-review --branch                           # Against auto-detected base branch
/code-review --branch develop                   # Against specific branch
/code-review --files src/Service/OrderService.php  # Specific files
/code-review --quick                            # Coding standards + linting only
```

## Execution Protocol

**Execute all phases automatically without pausing for user input.**

### Phase 0: Context Extraction

**Run ONE terminal command. Do NOT read source files. Move to Phase 1 immediately.**

**Default (uncommitted):**
```bash
REVIEW_DIR=.review-tmp/code-review/$(git rev-parse --short HEAD 2>/dev/null || echo no-commit) && mkdir -p "$REVIEW_DIR" &&(git diff && git diff --cached) > "$REVIEW_DIR/diff.txt"
```

**If no uncommitted changes, or `--branch`:**
```bash
REVIEW_DIR=.review-tmp/code-review/$(git rev-parse --short HEAD 2>/dev/null || echo no-commit) && mkdir -p "$REVIEW_DIR" &&BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main") && git diff "$BASE"...HEAD > "$REVIEW_DIR/diff.txt"
```

**`--staged`:**
```bash
REVIEW_DIR=.review-tmp/code-review/$(git rev-parse --short HEAD 2>/dev/null || echo no-commit) && mkdir -p "$REVIEW_DIR" &&git diff --cached > "$REVIEW_DIR/diff.txt"
```

**`--branch <name>`:**
```bash
REVIEW_DIR=.review-tmp/code-review/$(git rev-parse --short HEAD 2>/dev/null || echo no-commit) && mkdir -p "$REVIEW_DIR" &&git diff <name>...HEAD > "$REVIEW_DIR/diff.txt"
```

**`--files`:**
```bash
REVIEW_DIR=.review-tmp/code-review/$(git rev-parse --short HEAD 2>/dev/null || echo no-commit) && mkdir -p "$REVIEW_DIR" &&git diff -- <file1> <file2> > "$REVIEW_DIR/diff.txt" && [ -s "$REVIEW_DIR/diff.txt" ] || echo "NO_DIFF_FILES"
```

If `--files` returns `NO_DIFF_FILES`, stop: "No changes found in specified files."

Search for `project-constitution.md` (repo root, `docs/`, `.github/`). Abort only if: no diff, not a git repo, or branch doesn't exist.

### Phase 1: Parallel Agent Analysis

**Standard: 5 agents in parallel** (no pr-quality — there is no PR). **Quick: 2 agents** (coding-standards + linting).

Pass `$REVIEW_DIR/diff.txt` file path to each agent — they will load it with `readFile`. Do NOT save agent responses to files.

### Phase 2: Hallucination Detection

Pass all agent JSON responses directly inline to hallucination-detector (along with the diff file path). Do NOT run terminal commands to save intermediate files. Abort if hallucinations found.

### Phase 3-4: Risk Scoring & Output

Risk score (1-10): critical>0 → 10 | high≥3 → 9 | high=2 → 8 | high=1 → 7 | medium≥5 → 6 | medium≥3 → 5 | medium>0 → 4 | low>0 → 3 | else → 1

```markdown
## Code Review - Local Changes

**Risk Score: X/10**
**Review Confidence: XX%**
**Diff source:** [uncommitted / staged / branch:<name> / files:...]

### Critical / High / Medium Issues (N)
- [ ] [Issue title] ([file:line])

### Suggestions (N)
- [Issue title] ([file:line])

---
**Agents:** [list] | **Framework:** [detected] | **Constitution:** [found/not found]
**Tooling:** PHPStan [level] | Psalm [equivalent] (from linting agent, if provided)
```

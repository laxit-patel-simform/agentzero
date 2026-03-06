# Quick Reference

## Slash Commands

| Command | Use Case | Parameters |
|---------|----------|-----------|
| `/pr-review <N>` | Review PR #N | `--dry-run`, `--quick` |
| `/code-review` | Review local changes | `--staged`, `--branch`, `--files`, `--quick` |
| `/generate-constitution` | Generate project standards | (none) |

## Agent Capabilities

| Agent | Phase | Purpose |
|-------|-------|---------|
| coding-standards | 1 | PSR-12 + any framework (auto-detected) |
| linting | 1 | Type safety, dead code, complexity |
| functional-review | 1 | Business logic vs constitution |
| test-coverage | 1 | Test quality and gaps (auto-detects frameworks) |
| security | 1 | Security risks and OWASP patterns |
| pr-quality | 1 | PR metadata quality |
| hallucination-detector | 2 | Verify all claims |

## Parallel Execution

Phase 1 agents run simultaneously (not sequentially). Total time: ~8 minutes (Phase 0 + 1 + 1.5 + 2 + output).

## Audit Trail

All agent JSON outputs are saved to `.review-tmp/<review-type>/<id>/`:
- `diff.txt` — the diff analyzed
- `metadata.json` — PR metadata (pr-review only)
- `coding-standards.json`, `linting.json`, etc. — each agent's raw output

## Setup (1 minute)

```bash
# Copy to your project
cp -r .github/ /path/to/your-project/

# Optional: Create project standards
/generate-constitution
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Agents not parallel | Ensure orchestrator is invoked via prompt file |
| Agent timeout | Use `--quick` (coding-standards + linting only) |
| Commands not found | Clear Copilot cache: Cmd+Shift+P → "Clear Copilot Cache" |
| Missing constitution | Run `/generate-constitution` first |
| Agent outputs not saved | Orchestrator saves them in Phase 1.5 via `runInTerminal` |
| File links broken in PR | File refs use backtick code format to prevent auto-linking |
| generate-constitution blocked | Uses `readFile`/`search` primarily; falls back from terminal if blocked |

## Files Structure

```
.github/
├── agents/          <- 9 agents (1 orchestrator + 7 reviewers + 1 generator)
├── prompts/         <- Slash command definitions
└── instructions/    <- Framework-specific guides
```

## Key Design Principles

- Framework auto-detected (Symfony, Laravel, or generic PHP)
- Falls back to PSR-12 if no framework detected
- Agents only analyze changed code (diff-only)
- No setup required except copying `.github/` directory
- Works with any PHP project
- Full Copilot compatibility

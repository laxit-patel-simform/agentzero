---
applyTo: ["agents/**", "registry.json"]
---
# Assimilation Rules
1. **New Agent Detection:** When a new folder is added to `agents/`, immediately check for `manifest.json`.
2. **Registry Sync:** If an agent is valid but missing from `registry.json`, generate the JSON entry for it.
3. **Stub Relocation:** If agent files are found directly in the agent's root or a `.github` folder inside the agent, suggest moving them to `stubs/` per Phase 1 standards.
4. **Path Resolution Rule:** Ensure that file paths in `manifest.json` **DO NOT** include the `stubs/` prefix. They must be relative to the `stubs/` directory (e.g., use `.github/agents/file.md`).
5. **Validation Command:** Always remind the user to run `make verify` to confirm structural integrity.

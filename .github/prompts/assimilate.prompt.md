---
description: "Onboard and structure a new agent"
agent: assimilator
---
# Action
I am providing you with the source files for a new (or un-assimilated) agent. Please perform the following "Intelligence Engineer" tasks:

1. **Identification:** Extract the agent's ID and name from the provided files.
2. **Standardization:** Propose the movement of all `.agent.md`, `.prompt.md`, and `.instructions.md` files into the `agents/<id>/stubs/.github/` directory.
3. **Manifest Generation:** Create a complete `manifest.json` that follows the "Intelligence + Stubs" architecture (ensuring file paths do NOT include the `stubs/` prefix and using `author` instead of `version`).
4. **Registry Entry:** Provide the JSON snippet for the root `registry.json` (id, author, description).
5. **Validation:** Remind the user to run `make verify` after applying these changes.

# New Agent Files
${selection}

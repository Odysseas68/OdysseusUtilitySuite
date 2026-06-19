---
name: ous-minimal-addon-patch
description: Make small, safe, reviewable Odysseus Utility Suite code changes. Use for normal OUS bug fixes and feature edits that should preserve stable names, module boundaries, SavedVariables, slash commands, load order, formatting, and architecture.
---

# OUS Minimal Addon Patch

1. Read `AGENTS.md` and inspect the target file before proposing changes.
2. Work one file at a time unless the user explicitly requests a multi-file change.
3. Start every new Lua file with the exact `AGENTS.md` File Header Rule, using its relative path and the current `YYYY.MM.DD` version.
4. Identify the root cause and verify uncertain Retail APIs with `$ous-wow-retail-api-check`.
5. Preserve stable functions, tables, frames, modules, SavedVariables keys, slash commands, formatting, and TOC order.
6. Prefer a targeted edit or helper over a refactor. Do not add dependencies or invent a helper system.
7. Keep enUS text and minimal comments that explain only non-obvious reasons.
8. Use `OUS.LogDebug("ModuleName", "message")` for routine debug output.
9. Check relevant edge cases and run focused static or available tests.

Report the change, files changed, safety rationale, edge cases, and in-game testing steps.

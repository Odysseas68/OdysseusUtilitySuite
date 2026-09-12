---
name: ous-minimal-addon-patch
description: Make small, safe, reviewable Odysseus Utility Suite code changes. Use for normal OUS bug fixes and feature edits that should preserve stable names, module boundaries, SavedVariables, slash commands, load order, formatting, and architecture.
---

# OUS Minimal Addon Patch

1. Read `AGENTS.md` and inspect the target file before proposing changes.
2. Work one file at a time unless the user explicitly requests a multi-file change.
3. Follow the `AGENTS.md` File Header Rule for Lua files: give every new Lua file the standard OUS header, preserve an existing header, and update its `Version` date when making meaningful functional changes. Cosmetic-only changes do not require a version update.
4. Identify the root cause and verify uncertain Retail APIs with `$ous-wow-retail-api-check`.
5. Preserve stable functions, tables, frames, modules, SavedVariables keys, slash commands, formatting, and TOC order.
6. Prefer a targeted edit or helper over a refactor. Do not add dependencies or invent a helper system.
7. Keep enUS text and add concise one-line comments before major helpers, public OUS APIs, and non-obvious integration boundaries.
8. Prefer standard third-party integration APIs over addon internals; isolate optional compatibility behind nil-guarded helpers.
9. Use `OUS.LogDebug("ModuleName", "message")` for routine debug output.
10. Keep verification proportional: one initial worktree check, directly relevant inspection, one focused implementation pass, targeted validation, one final diff review, and `git diff --check` once.
11. Run LuaCheck only on changed Lua files unless broader validation is justified. Report warning baselines separately from errors; do not repeatedly reprove unchanged HEAD, origin, status, or warning counts.
12. For runtime-sensitive behavior, finish targeted static checks, ask for focused in-game validation, and wait for that evidence before commit finalization when practical.
13. Distinguish verified source facts, verified runtime behavior, source-supported inference, and assumptions in analysis and handoff.

Report the change, files changed, safety rationale, edge cases, and in-game testing steps.

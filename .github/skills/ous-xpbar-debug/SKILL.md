---
name: ous-xpbar-debug
description: Debug or edit the OUS XPBar, reputation, favorites, and Delves flow. Use when working in xpbar_core.lua, xpbar_engine.lua, xpbar_delves.lua, xpbar_favorites.lua, or xpbar_config.lua, especially for login, reload, zoning, max-level reputation, watched factions, persistence, or delve completion transitions.
---

# OUS XPBar Debug

1. Read `AGENTS.md`, then trace the existing update flow across only the XPBar files needed for the issue.
2. Preserve module boundaries, TOC order, and current SavedVariables shapes.
3. Prefer sticky, session-safe state fixes over broad visibility heuristics.
4. Verify login, reload, and zoning timing before changing initialization.
5. Keep reputation useful at max level when XP no longer applies.
6. Preserve favorite-faction persistence and handle watched-faction clearing explicitly.
7. Treat delve completion as a transition that may change scenario, map, or instance state after the final boss.
8. Verify uncertain scenario, map, XP, or reputation APIs with `$ous-wow-retail-api-check`.
9. Apply `$ous-minimal-addon-patch` constraints to the final edit.

Test login, reload, zoning, max-level mode, favorites, watched-faction clearing, and delve completion as relevant.

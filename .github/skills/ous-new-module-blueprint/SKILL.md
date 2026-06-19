---
name: ous-new-module-blueprint
description: Add a new independent module to Odysseus Utility Suite with correct namespace, defaults, SavedVariables, reset flow, TOC placement, config, OUS2, Help, and Toolbox integration. Use only when creating a new OUS module or reviewing its complete project wiring.
---

# OUS New Module Blueprint

1. Read `AGENTS.md`, `Core.lua`, the TOC, and the closest existing module pattern.
2. Start every new Lua file with the exact `AGENTS.md` File Header Rule.
3. Use `local addonName, OUS = ...` and keep shared exports on `OUS`.
4. Add `OdysseusDB.modules.<moduleName>` to the `ADDON_LOADED` defaults block.
5. Initialize account-wide and per-character settings under module-specific keys without altering existing structures.
6. Expose `OUS.<moduleDefaults>` when the module has settings and include it in the established reset flow.
7. Keep the module independent and event-driven; avoid polling and cross-module coupling.
8. Place the engine before config files in the TOC without reordering existing entries.
9. Add legacy config, OUS2 page, Help or slash-command documentation, and Toolbox integration only when applicable.
10. Place OUS2 page files after `Config2\\OUS2Config.lua` and follow `$ous-config2-ui-edit`.
11. Verify unfamiliar APIs with `$ous-wow-retail-api-check` and apply `$ous-minimal-addon-patch` per file.

Review the module file, toggle default, database defaults, reset integration, TOC, config surfaces, Help, and Toolbox before completion.

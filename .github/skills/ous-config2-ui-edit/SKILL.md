---
name: ous-config2-ui-edit
description: Build or edit the next-generation OUS2 configuration UI. Use for Config2/OUS2Theme.lua, Config2/OUS2Config.lua, Config2/OUS2Page_*.lua, OUS2 assets, or OUS2 documentation while preserving shared theme APIs, page registration, manual NineSlice behavior, and the legacy /ous UI.
---

# OUS2 Config UI Edit

1. Read `AGENTS.md` and inspect `OUS2Theme.lua` plus the relevant config or page file.
2. Alias `local T = OUS.Theme` and `local C = OUS.Config2`.
3. Start each new OUS2 Lua page with the exact `AGENTS.md` File Header Rule.
4. Use `T.Tex`, `T.Colors`, `T.Fonts`, `T.Frame`, `T.Scroll`, and `T.Icons`; do not duplicate paths, colors, fonts, or constants in page files.
5. Parent pages to `C.pageContainer`, call `SetAllPoints()` and `Hide()`, implement `Refresh()`, and register the exact documented page key.
6. Wire hover help through `C.SetHelpText` and `C.ClearHelpText`.
7. Use manual NineSlice placement. Never call `NineSliceUtil.ApplyLayout` for custom TGA files.
8. Follow the documented Retail ScrollBox pattern for static scrollable content.
9. Remove debug grids, underlays, and cyan borders before completion. Do not use emoji.
10. Keep the legacy `/ous` config untouched unless explicitly requested.
11. Apply `$ous-minimal-addon-patch` and verify uncertain frame APIs with `$ous-wow-retail-api-check`.

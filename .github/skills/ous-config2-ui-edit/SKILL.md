---
name: ous-config2-ui-edit
description: Build or edit the next-generation OUS2 configuration UI. Use for Config2/OUS2Theme.lua, Config2/OUS2Config.lua, Config2/OUS2Page_*.lua, OUS2 assets, or OUS2 documentation while preserving shared theme APIs, page registration, manual NineSlice behavior, and the legacy /ous UI.
---

# OUS2 Config UI Edit

1. Read `AGENTS.md` and inspect `OUS2Theme.lua` plus the relevant config or page file.
2. Alias `local T = OUS.Theme` and `local C = OUS.Config2`.
3. Start each new OUS2 Lua page with the exact `AGENTS.md` File Header Rule.
4. Use `T.Tex`, `T.Colors`, `T.Fonts`, `T.Frame`, `T.Scroll`, `T.Icons`, and `T.Card`; do not duplicate paths, colors, fonts, or constants in page files.
5. Parent pages to `C.pageContainer`, call `SetAllPoints()` and `Hide()`, implement `Refresh()`, and register the exact documented page key with `C.RegisterPage("PageKey", pageFrame, Refresh, sidebarFrame)`. The fourth argument is optional.
6. Wire hover help through `C.SetHelpText` and `C.ClearHelpText`.
7. Use manual NineSlice placement. Never call `NineSliceUtil.ApplyLayout` for custom TGA files.
8. Follow the documented Retail ScrollBox pattern for static scrollable content.
9. For manually resizable OUS2 frames, capture `GetLeft()` and `GetTop()`, normalize to a stable `UIParent` `TOPLEFT` anchor, call `StopMovingOrSizing()`, then call `StartSizing()`.
10. Guard resize handlers when the frame is locked or hidden, keep resize handles above page and sidebar content, prevent overlap with interactive controls, and retest all handles after adding overlays or sidebars.
11. Remove debug grids, underlays, and cyan borders before completion. Do not use emoji.
12. Keep the legacy `/ous` config untouched unless explicitly requested.
13. Apply `$ous-minimal-addon-patch` and verify uncertain frame APIs with `$ous-wow-retail-api-check`.
14. Use `T.Card.*` for shared dashboard card sizing, padding, icon, chevron, spacing, and layout values; do not duplicate card constants in page files.
15. Resolve module card backgrounds through the theme registry only: `T.Tex("CardNormal")`, `T.Tex("CardHover")`, and `T.Tex("CardSelected")`. These map to `CardBG_Normal.tga`, `CardBG_Hover.tga`, and `CardBG_Selected.tga`; do not hardcode filenames or texture paths in page files.
16. Treat the normal, hover, and selected textures as one shared card-state set. Preserve identical card geometry and swap the background texture when state changes instead of stacking independently sized artwork.
17. Keep the module icon, title, description, and chevron as Lua UI layers above the shared background texture. Do not bake module-specific content into the card assets.
18. For page-specific right-sidebar content, create a sidebar frame parented to `C.sidebarContainer`, call `SetAllPoints()` and `Hide()`, and pass it as the optional fourth argument to `C.RegisterPage`. Let the page-switching framework manage its visibility.
19. Use `T.Tex("CardNormal")` for non-interactive sidebar card panels. Do not use `CardHover` or `CardSelected` unless the sidebar panel itself gains an explicitly approved interactive state. Keep action controls on the established `ActionNormal`, `ActionHover`, and `ActionPressed` assets.
20. Use `T.Card.Padding` for reusable internal card and sidebar spacing where appropriate; do not change or duplicate `T.Card` values in page files.
21. Phase 3 is General dashboard refinement. The General page, shared module-card assets, `T.Card` constants, page-specific sidebar architecture, and resize framework are implemented; preserve them instead of recreating parallel systems.
22. Phase 3 still requires module-card navigation, module count, enabled/disabled state display, Global Options functionality, and Reset functionality. Do not document these as complete. The next major milestone is the Utilities OUS2 page.

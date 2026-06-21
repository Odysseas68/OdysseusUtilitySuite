---
name: ous-config2-ui-edit
description: Build or edit the next-generation OUS2 configuration UI. Use for Config2/OUS2Theme.lua, Config2/OUS2Config.lua, Config2/OUS2Page_*.lua, OUS2 assets, or OUS2 documentation while preserving shared theme APIs, page registration, manual NineSlice behavior, and the legacy /ous UI.
---

# OUS2 Config UI Edit

1. Read `AGENTS.md` and inspect `OUS2Theme.lua` plus the relevant config or page file.
2. Alias `local T = OUS.Theme` and `local C = OUS.Config2`.
3. Follow the `AGENTS.md` File Header Rule for OUS2 Lua files: give every new page the standard OUS header, preserve an existing header, and update its `Version` date for meaningful functional changes. Cosmetic-only changes do not require a version update.
4. Use `T.Tex`, `T.Colors`, `T.Fonts`, `T.Frame`, `T.Scroll`, `T.Scale`, `T.Icons`, and `T.Card`; do not duplicate paths, colors, fonts, or constants in page files.
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
21. OUS2 is transitioning from Phase 3 General Dashboard into Phase 4 Module Pages. Utilities and Openables are functional OUS2 pages; preserve their existing database wiring, `Refresh()` behavior, command delegation, and hover help while adding focused polish.
22. Build reusable custom numeric controls with the OUS2 scale-control assets and `T.Scale.*`. Avoid Blizzard `OptionsSliderTemplate` for OUS2 custom numeric controls unless the user explicitly requests it.
23. Resolve scale-control artwork through `T.Tex("ScaleTrack")`, `T.Tex("ScaleFill")`, `T.Tex("ScaleThumb")`, `T.Tex("ScaleArrowLeft")`, `T.Tex("ScaleArrowLeftH")`, `T.Tex("ScaleArrowRight")`, `T.Tex("ScaleArrowRightH")`, and `T.Tex("ScaleEditBox")`; do not hardcode their filenames or paths.
24. Use `T.Scale.minValue`, `T.Scale.maxValue`, `T.Scale.step`, and the shared track, thumb, arrow, and edit-box dimensions instead of duplicating numeric-control constants in page files.
25. Preserve the current Utilities page database wiring and `Refresh()` behavior. Future layout polish should replace one full-width setting row per toggle with a cleaner two-column layout to reduce unused horizontal space, without changing SavedVariables formats or `Utilities.lua` logic.
26. Current `C.SetHelpText` / `C.ClearHelpText` hover help is valid. A future OUS2 pattern should centralize help strings in one shared help-description table or file, similar to a dictionary database; do not implement that help store or extract helpers until explicitly requested.
27. Current focus is Phase 4 module pages and OUS2 control polish. Openables scale-control replacement is pending; General card navigation, enabled state, Global Options, and reset work remain deferred or incomplete.

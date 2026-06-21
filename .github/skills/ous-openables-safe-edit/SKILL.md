---
name: ous-openables-safe-edit
description: Safely edit the OUS Openables engine, item database, or OUS2 settings page. Use for Openables.lua, OpenablesDB.lua, or Config2/OUS2Page_Openables.lua when secure buttons, item macros, dragging, delayed item data, runtime settings, live lock behavior, management actions, or scale-control presentation are involved.
---

# OUS Openables Safe Edit

1. Read `AGENTS.md` and determine whether the change affects `Openables.lua`, `OpenablesDB.lua`, or `Config2\OUS2Page_Openables.lua`. Preserve `OUS.OpenablesDB[itemID] = minQuantity` plus `OdysseusDB.openables`.
2. Keep a plain draggable container with a `SecureActionButtonTemplate` child.
3. Configure secure use as `type=macro` with `/use item:ID`.
4. Never set `OnMouseDown` or `OnMouseUp` on the secure button.
5. Never call `C_Container.UseContainerItem` for the secure button path.
6. Use `PostClick` only for post-action logic.
7. Guard nil and delayed item information with existing loading patterns.
8. Do not change the database format without explicit approval.
9. Verify secure, item, and container APIs with `$ous-wow-retail-api-check` and apply `$ous-minimal-addon-patch`.
10. Preserve the functional OUS2 Openables page, including its DB-backed settings, `Refresh()` behavior, existing command integration, and management actions.
11. Route OUS2 lock/unlock changes through `OUS.Openables.SlashHandler("lock")` / `("unlock")` or an equivalent public live-behavior path; do not only toggle `OdysseusDB.openables.locked`.
12. Replace the temporary Openables scale controls with the reusable OUS2 custom scale control using `T.Tex` scale assets and `T.Scale.*`. Do not use Blizzard `OptionsSliderTemplate` unless explicitly requested.
13. Keep management actions delegated to existing Openables command paths. Management-frame strata or side anchoring may need a later focused review when OUS2 is open; do not alter those frames during unrelated page work.

Test combat lockdown, dragging, item loading, quantity thresholds, and repeated secure clicks for engine changes. For OUS2 page changes, test checkbox refresh, live lock/unlock, scale adjustment, management commands, persistence after reload, and frame layering as relevant.

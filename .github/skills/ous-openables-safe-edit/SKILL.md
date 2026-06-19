---
name: ous-openables-safe-edit
description: Safely edit the OUS Openables engine or item database. Use for Openables.lua or OpenablesDB.lua when secure buttons, item macros, dragging, delayed item data, quantity thresholds, runtime settings, or the static item database are involved.
---

# OUS Openables Safe Edit

1. Read `AGENTS.md` and preserve `OUS.OpenablesDB[itemID] = minQuantity` plus `OdysseusDB.openables`.
2. Keep a plain draggable container with a `SecureActionButtonTemplate` child.
3. Configure secure use as `type=macro` with `/use item:ID`.
4. Never set `OnMouseDown` or `OnMouseUp` on the secure button.
5. Never call `C_Container.UseContainerItem` for the secure button path.
6. Use `PostClick` only for post-action logic.
7. Guard nil and delayed item information with existing loading patterns.
8. Do not change the database format without explicit approval.
9. Verify secure, item, and container APIs with `$ous-wow-retail-api-check` and apply `$ous-minimal-addon-patch`.

Test combat lockdown, dragging, item loading, quantity thresholds, and repeated secure clicks as relevant.

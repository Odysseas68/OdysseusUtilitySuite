---
name: ous-utilities-safe-edit
description: Safely edit the OUS Utilities engine or OUS2 Utilities settings page. Use for Utilities.lua or Config2/OUS2Page_Utilities.lua changes involving rare announcing, auto repair, junk selling, existing database wiring, or Utilities-page presentation.
---

# OUS Utilities Safe Edit

1. Read `AGENTS.md` and determine whether the change affects `Utilities.lua` engine behavior or only `Config2\OUS2Page_Utilities.lua` presentation.
2. Preserve `OdysseusDB.modules.utilities`, `OdysseusDB.utilities`, and `OdysseusDB.utilities.junkSell` structures. Preserve the OUS2 Utilities page's current database wiring and `Refresh()` behavior.
3. Restore prior waypoint pins after rare-announcer operations.
4. Keep auto repair driven by `MERCHANT_SHOW` and respect existing short-delay behavior because `MerchantFrame:IsShown()` may initially be false.
5. Collect the junk seller pending queue once per merchant session.
6. Keep bag and slot queue entries stable through batch processing.
7. Apply blacklist behavior at the established collection point.
8. Reuse existing batch and timer logic unless the task explicitly changes it.
9. Verify merchant, map, and container APIs with `$ous-wow-retail-api-check`; apply `$ous-minimal-addon-patch`.
10. For future Utilities-page polish, replace the full-width setting rows with a cleaner two-column layout while preserving the current controls, database keys, and behavior.
11. Keep the existing hover-help behavior. Help strings should eventually move into one shared OUS2 help-description table or file, but do not implement that store or extract helpers yet.
12. For page-only layout or presentation work, do not modify `Utilities.lua` logic or SavedVariables formats.

For engine changes, test repeated merchant opens, early merchant closure, repairs, blacklisted junk, bag changes, and waypoint restoration as relevant. For OUS2 page changes, test checkbox clicks, `Refresh()`, hover help, and persistence after reload.

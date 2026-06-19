---
name: ous-utilities-safe-edit
description: Safely edit the OUS Utilities module. Use for Utilities.lua changes to rare announcing and waypoint restoration, merchant auto repair, junk-selling queues, blacklist behavior, bag and slot handling, merchant timing, or existing batch and timer logic.
---

# OUS Utilities Safe Edit

1. Read `AGENTS.md` and isolate the rare announcer, auto repair, or junk seller path being changed.
2. Preserve `OdysseusDB.utilities` and `OdysseusDB.utilities.junkSell` structures.
3. Restore prior waypoint pins after rare-announcer operations.
4. Keep auto repair driven by `MERCHANT_SHOW` and respect existing short-delay behavior because `MerchantFrame:IsShown()` may initially be false.
5. Collect the junk seller pending queue once per merchant session.
6. Keep bag and slot queue entries stable through batch processing.
7. Apply blacklist behavior at the established collection point.
8. Reuse existing batch and timer logic unless the task explicitly changes it.
9. Verify merchant, map, and container APIs with `$ous-wow-retail-api-check`; apply `$ous-minimal-addon-patch`.

Test repeated merchant opens, early merchant closure, repairs, blacklisted junk, bag changes, and waypoint restoration as relevant.

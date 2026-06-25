---
name: ous-flightmaster-safe-edit
description: Safely edit OUS flight timing, taxi routing, route display, or learned-route behavior. Use for Flightmaster.lua, FlightRouting.lua, flightdata.lua, or Odysseus_RoutingDB.lua while preserving arrival thresholds, stored routes, generated data formats, and the independent tooltip.
---

# OUS Flightmaster Safe Edit

1. Read `AGENTS.md` and determine whether the issue is engine logic, route display, learned-route storage, or generated data.
2. Treat `flightdata.lua` and `Odysseus_RoutingDB.lua` as data unless the task explicitly changes their format.
3. Preserve learned-route behavior, route timing, and arrival thresholds.
4. Consider both bundled and newly learned routes when changing route matching.
5. Preserve the independent tooltip because third-party tooltip changes may introduce taint or conflicts.
6. Prefer standard integration APIs over third-party addon internals and keep compatibility boundaries documented.
7. Keep display-only fixes out of learning and storage logic.
8. Verify taxi, map, frame, and tooltip APIs with `$ous-wow-retail-api-check` when uncertain.
9. Apply `$ous-minimal-addon-patch` constraints to the final edit.

Test bundled routes, learned routes, arrival handling, route display, and tooltip isolation as relevant.

# BuffBars Design

## 1. Purpose

BuffBars is a future Odysseus Utility Suite module candidate for Retail-safe buff, debuff, and enhancement bar display.

The validated reference addon in `Reference\OdysseusBuffBarsTest\` proves that a Retail 12.0+ aura bar approach can remain stable in open-world, dungeon, and raid testing. The reference passed testing with no Lua errors captured by BugGrabber, but it should be treated as a proof-of-concept and design source, not code to copy directly into OUS.

## 2. Goals

- Provide Retail-safe buff and debuff bars.
- Use secret-value-safe aura scanning and display rules.
- Build a reusable aura engine that can serve bars, filters, and future UI surfaces.
- Integrate with OUS2 through a conservative first settings page.
- Keep the first OUS release small, safe, and reviewable.

## 3. Non-Goals

- Do not port ElkBuffBars wholesale.
- Do not port the standalone test configuration UI.
- Do not add Classic, MoP, or other legacy compatibility branches.
- Do not add profiles initially.
- Do not expose Blizzard aura-frame hiding until the behavior is reviewed for OUS.

## 4. Proposed File Architecture

### `BuffBars.lua`

Module bootstrap, defaults, SavedVariables initialization, event registration, slash command ownership if needed, refresh flow, and public OUS API.

### `BuffBars_Auras.lua`

Retail aura scanning, secret-safe aura data handling, previous-value cache, spellID-based filtering, enhancement classification, and sorting.

### `BuffBars_Bars.lua`

Aura group frames, pooled bars, status fills, icons, text layers, tooltips, secure cancel overlays, anchor layout, and combat-safe rendering.

### `BuffBars_Config.lua`

Legacy `/ous` integration only if needed after the module engine is stable. The reference addon's standalone config frame should not be copied directly.

### `Config2/OUS2Page_BuffBars.lua`

Conservative OUS2 page for safe first-release controls and status. Advanced filters and overrides should wait until public APIs stabilize.

## 5. Retail-Safe Aura Rules

- Use `C_UnitAuras.GetAuraDataByIndex(unit, index, filter)` for aura scans.
- Use `auraInstanceID` as the stable cache key.
- Preserve previous readable values when current aura fields become unreadable or secret.
- Gate unsafe value handling through `issecretvalue` and `canaccessvalue`.
- Use `C_UnitAuras.GetAuraDuration(unit, auraInstanceID)` for duration objects.
- Use `DurationObject:FormatRemainingDuration(formatter)` for aura timer text.
- Use `C_UnitAuras.GetUnitAuraInstanceIDs(...)` for aura ordering instead of sorting secret fields in Lua.
- Treat `expirationTime == 0` as timeless.
- Filter expired auras only when expiration is readable, numeric, positive, and `<= GetTime()`.
- Match whitelist and blacklist entries by readable numeric `spellID`.
- Pass non-nil texture tokens through to `Texture:SetTexture(...)`; do not require texture IDs to be readable first.
- Avoid secure cancel overlay creation, attribute changes, or anchor mutation in combat.

## 6. Proposed OUS DB Shape

BuffBars should use account-wide settings under:

```lua
OdysseusDB.buffBars
```

Keep the first DB shape high-level and migration-friendly. Initial settings should likely cover module enablement, anchor lock/show state, group visibility, and simple group display defaults. Do not invent full filter, override, profile, or color tables until the production module API is designed.

## 7. Event Flow

Likely events:

- `ADDON_LOADED`
- `PLAYER_ENTERING_WORLD`
- `UNIT_AURA`
- `WEAPON_ENCHANT_CHANGED`
- `WEAPON_SLOT_CHANGED`
- `PLAYER_REGEN_DISABLED`
- `PLAYER_REGEN_ENABLED`

`UNIT_AURA` should refresh only affected configured units. Combat events should lock or defer unsafe configuration and secure overlay work.

## 8. Frame Ownership and Combat Safety

- Aura groups should be parented to `UIParent`.
- Bar frames should be pooled and reused.
- Secure cancel overlays should be parented to `UIParent`.
- Secure overlays should not be created, cleared, reanchored, or reconfigured in combat.
- Combat should not rebuild group anchors or clear/reapply protected-adjacent frame structure.
- Existing anchors can continue to follow parent group height changes, but structural anchor changes should wait until out of combat.

## 9. OUS2 Integration Plan

The first OUS2 BuffBars page should be conservative:

- Enable module.
- Lock anchors.
- Show or hide anchors.
- Refresh button.
- Read-only runtime status.
- Simple group cards for BUFFS, DEBUFFS, and ENCHANTMENTS.

Defer filters, overrides, routing, Blizzard aura-frame hiding, and advanced visual controls until stable public APIs exist.

## 10. Risks / Unknowns

- `C_UnitAuras.GetAuraDataByIndex` may need a small guarded wrapper before production use.
- Weapon enchant timer behavior should be verified in Retail 12.0+.
- Name-based enhancement classification should remain a fallback heuristic only.
- Blizzard aura-frame hiding requires separate OUS review before exposure.
- Long spell names, large stack counts, and narrow bars may visually clip.
- Sorting edge cases may occur if Blizzard sorted aura IDs omit scanned aura IDs.
- Very short combat-generated proc/passive auras may briefly show near-expired timer text.

## 11. Staged Implementation Plan

### Phase A: Documentation and Design Only

Capture the validated reference rules, production architecture, risks, and acceptance criteria.

### Phase B: OUS Module Skeleton

Create the module files and DB defaults, likely disabled by default or guarded until testing is complete.

### Phase C: Aura Engine

Port the Retail-safe aura scanning rules into `BuffBars_Auras.lua` with OUS namespace conventions.

### Phase D: Bar Renderer

Add pooled bar rendering, group anchors, timer text, tooltips, and secure cancel overlay handling.

### Phase E: Conservative OUS2 Page

Expose only safe page controls: enable, lock/show anchors, refresh, status, and simple group cards.

### Phase F: Filters, Overrides, and Polish

Add spellID filters, overrides, advanced visuals, and any reviewed Blizzard-frame options after public APIs stabilize.

## 12. Acceptance Criteria

- No BugGrabber errors in open-world, dungeon, and raid testing.
- No secret-value errors.
- No combat taint.
- No protected frame mutation in combat.
- OUS2 settings are live and safe.
- Saved settings persist through `/reload`.
- Documentation remains synchronized across `BUFFBARS_DESIGN.md`, `TODO_v2.md`, `ARCHITECTURE.md`, `CLAUDE.md`, and `CHANGELOG.md`.

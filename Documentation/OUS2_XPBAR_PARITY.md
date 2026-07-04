# OUS2 XP Bar Parity Plan

## 1. Purpose

This document records the remaining OUS2 parity work for the legacy XP Bar, Reputation, Favorites, and Delves configuration before implementation.

The legacy `xpbar_config.lua` UI is the checklist. The current OUS2 targets are `Config2\OUS2Page_XPBar.lua` and `Config2\OUS2Page_Delves.lua`.

This is a planning document only. It does not approve SavedVariables changes, TOC changes, runtime rewrites, or BuffBars work.

## 2. Source Files Audited

* `AGENTS.md`
* `CLAUDE.md`
* `Documentation\ARCHITECTURE.md`
* `Documentation\TODO_v2.md`
* `xpbar_core.lua`
* `xpbar_engine.lua`
* `xpbar_config.lua`
* `xpbar_favorites.lua`
* `xpbar_delves.lua`
* `Config2\OUS2Page_XPBar.lua`
* `Config2\OUS2Page_Delves.lua`

## 3. Current OUS2 XP Bar Status

OUS2 currently provides an `XPBar` hub with child views for Global, Experience, Reputation, Favorites, and Help. Delves is a separate registered page with a Back to XP Bar action.

Current OUS2 coverage includes:

* Account-wide module toggle for `OdysseusDB.modules.xpBar`.
* Global checkboxes for `hideBlizz`, `shortNumbers`, `autoHide`, and `showRestIcon`.
* Global scale controls for `xpFontSize`, `repDisplayTime`, `fadeDelay`, `activeAlpha`, `fadedAlpha`, and `barBorderSize`.
* Global media/color controls for `xpFont`, `barBorderName`, and `barBorderColor`.
* Global Reset Defaults.
* XP text template, width, height, scale, XP/rest/background/text color controls, and Experience Reset Defaults.
* Reputation text template, text color, standing colors, toast enabled, toast sound, faction menu modifier controls, and Reputation Reset Defaults.
* Read-only Favorites guidance.
* XP/Rep/Delves token help.
* Delves companion and journey templates, companion/journey colors, width, height, and scale controls.

Current OUS2 intentional improvements:

* The Reputation menu modifier is shown as four explicit buttons instead of a legacy cycle button.
* Template edit boxes commit on focus loss or Enter, which is more forgiving than Enter-only legacy behavior.
* Alpha controls are displayed as 0.0-1.0 scale controls while still writing the legacy percent DB keys.
* Delves is promoted to a separate left-navigation page while still linked from the XP Bar hub.

## 4. Legacy Parity Table

| Area | Legacy option | Legacy DB key / behavior | Current OUS2 status | Status | Recommended patch | Notes / risk |
|---|---|---|---|---|---|---|
| Global XP Bar settings | Enable XP Bar module | Legacy module toggle is account-wide under `OdysseusDB.modules.xpBar` through the main config/module system. | OUS2 Global has `Enable XP Bar Module`. | Present | None unless master-toggle behavior audit finds runtime gaps. | Confirm hiding both XP and Delves bars remains correct while active timers/favorites are open. |
| Global XP Bar settings | Global Font Size | `OdysseusDB.xpBar.xpFontSize`; legacy range 8-32; applies `OUS.ApplyFonts()`. | OUS2 has `Font Size`; range 8-32; applies fonts and updates bars. | Present | None. | Implemented; in-game visual update still belongs to final live-preview testing. |
| Fonts/media | Global Font | `OdysseusDB.xpBar.xpFont`; legacy uses LibSharedMedia font dropdown and `OUS.ApplyFonts()`. | OUS2 has a `Global Font` media dropdown using the existing media picker helper. | Present | None. | Implemented; verify dropdown layering and live font refresh in-game. |
| Global XP Bar settings | Hide Default Blizzard UI | `OdysseusDB.xpBar.hideBlizz`; legacy shows reload prompt and disables the checkbox while in an instance. | OUS2 has `Hide Blizzard XP/Rep Bars` and a reload popup. | Partial | Add the legacy instance-disable behavior or document intentional difference. | Avoid calling protected/Blizzard UI mutation paths from OUS2; runtime hiding remains owned by `OUS.ApplyBlizzardKiller()`. |
| Global XP Bar settings | Enable Auto-Hide / Mouseover Engine | `OdysseusDB.xpBar.autoHide`; legacy calls `OUS.WakeBars()` and `OUS.SleepBars()`. | OUS2 has `Auto-hide Bars`; calls wake/sleep helper. | Present | None. | Combat behavior is owned by engine sleep checks. |
| Global XP Bar settings | Abbreviate Numbers | `OdysseusDB.xpBar.shortNumbers`; legacy calls `OUS.UpdateBar()`. | OUS2 has `Abbreviate Large Numbers`; calls `OUS.UpdateBar()`. | Present | None. | Verify after max-level rep display and Delves journey text. |
| Auto-hide/fade behavior | Auto-Switch Display Time | `OdysseusDB.xpBar.repDisplayTime`; legacy range 5-60 seconds. | OUS2 has `Auto-Switch Display Time`; range 5-60 seconds. | Present | None. | Implemented with existing scale control and wake/sleep refresh path. |
| Auto-hide/fade behavior | Auto-Hide Fade Delay | `OdysseusDB.xpBar.fadeDelay`; legacy range 0-60 seconds. | OUS2 has `Auto-Hide Fade Delay`; range 0-60 seconds. | Present | None. | Implemented; 0-second delay remains valid legacy behavior. |
| Auto-hide/fade behavior | Active Opacity | `OdysseusDB.xpBar.activeAlpha`; legacy stores percent 10-100. | OUS2 has `Active Alpha`; UI range 0.1-1.0 and writes percent. | Present | None. | Current UI is an intentional OUS2 presentation improvement. |
| Auto-hide/fade behavior | Faded Opacity | `OdysseusDB.xpBar.fadedAlpha`; legacy stores percent 0-100. | OUS2 has `Faded Alpha`; UI range 0.0-1.0 and writes percent. | Present | None. | Current UI is an intentional OUS2 presentation improvement. |
| Borders | Bar Border Style | `OdysseusDB.xpBar.barBorderName`; legacy LibSharedMedia border dropdown and `OUS.ApplyXPBarBorders()`. | OUS2 has `Bar Border Style` media dropdown. | Present | None. | Implemented; verify dropdown layering and border refresh in-game. |
| Borders | Border Color | `OdysseusDB.xpBar.barBorderColor`; legacy color picker and `OUS.ApplyXPBarBorders()`. | OUS2 has `Border Color` picker. | Present | None. | Implemented; preserves `{ r, g, b }` table shape. |
| Borders | Bar Border Size | `OdysseusDB.xpBar.barBorderSize`; legacy range 0-50. | OUS2 has `Border Size`; range 0-50. | Present | None. | Implemented with existing scale control and border apply helper. |
| Reset defaults | Global Reset Defaults | Resets `hideBlizz`, `autoHide`, `repDisplayTime`, `fadeDelay`, `activeAlpha`, `fadedAlpha`, `xpFont`, `xpFontSize`, `barBorderName`, `barBorderSize`, and `barBorderColor`; applies Blizzard killer, fonts, borders, wake/sleep. | OUS2 has a Global `Reset Defaults` action for this scope. | Present | None. | Implemented as a section-scoped reset. |
| Experience bar settings | XP Text Format | `OdysseusDB.xpBar.xpTemplate`; legacy commits on Enter and updates bar. | OUS2 has `XP Text Template`; commits on Enter/focus loss and updates bar. | Present | None. | OUS2 commit behavior is more forgiving. |
| Experience bar settings | Main EXP Bar color | `OdysseusDB.xpBar.xpColor`; legacy color picker and `OUS.UpdateBar()`. | OUS2 has `Main EXP Bar` color picker. | Present | None. | Implemented; verify live preview in-game. |
| Experience bar settings | XP Text Color | `OdysseusDB.xpBar.xpTextColor`; legacy color picker and `OUS.UpdateBar()`. | OUS2 has `XP Text Color` picker. | Present | None. | Implemented; verify live preview in-game. |
| Experience bar settings | Rested Bar Color | `OdysseusDB.xpBar.restColor`; legacy color picker and `OUS.UpdateBar()`. | OUS2 has `Rested Bar` color picker. | Present | None. | Implemented; verify rested bar visible and hidden states. |
| Experience bar settings | Background Color | `OdysseusDB.xpBar.bgColor`; legacy color picker and `OUS.ApplyXPBarBg()`. | OUS2 has `Background` color picker. | Present | None. | Implemented; uses existing background apply helper. |
| Dimensions | Main Bar Width | `OdysseusDB.xpBar.xpBarWidth`; legacy range 100-1000. | OUS2 has `XP Bar Width`; range 100-800. | Partial | Adjust OUS2 range to 100-1000. | No DB change. |
| Dimensions | Main Bar Height | `OdysseusDB.xpBar.xpBarHeight`; legacy range 10-100. | OUS2 has `XP Bar Height`; range 4-80. | Partial | Align to 10-100 or document intentional difference. | Changing range affects only UI affordance, not saved structure. |
| Dimensions | Main Bar Scale | `OdysseusDB.xpBar.xpBarScale`; legacy range 0.5-2.0. | OUS2 has `XP Bar Scale`; range 0.5-3.0. | Partial | Align to 0.5-2.0 or document intentional wider range. | Larger scales may be useful but are not exact parity. |
| Experience bar settings | Show Rested Icon | `OdysseusDB.xpBar.showRestIcon`; legacy calls `OUS.UpdateBar()`. | OUS2 has `Show Rested Icon` under Global Behavior. | Present | None, unless moved to Experience for layout parity. | Location differs but behavior is present. |
| Reset defaults | Experience Reset Defaults | Resets `xpTemplate`, `xpColor`, `xpTextColor`, `restColor`, `bgColor`, `showRestIcon`, `xpBarWidth`, `xpBarHeight`, and `xpBarScale`; applies background. | OUS2 has an Experience `Reset Defaults` action for this scope. | Present | None. | Implemented; final review should confirm live refresh and `showRestIcon` placement. |
| Reputation bar settings | Reputation Text Format | `OdysseusDB.xpBar.repTemplate`; legacy commits on Enter and updates bar. | OUS2 has `Reputation Text Template`. | Present | None. | OUS2 commits on focus loss too. |
| Reputation bar settings | Reputation Text Color | `OdysseusDB.xpBar.repTextColor`; legacy color picker and `OUS.UpdateBar()`. | OUS2 has `Reputation Text Color` picker. | Present | None. | Implemented; existing engine reads this in `RenderReputationBar()`. |
| Reputation colors | Hated color | `OdysseusDB.xpBar.repColors.hated`. | OUS2 has a Hated standing color picker. | Present | None. | Implemented; preserves nested table shape. |
| Reputation colors | Hostile color | `OdysseusDB.xpBar.repColors.hostile`. | OUS2 has a Hostile standing color picker. | Present | None. | Implemented; preserves nested table shape. |
| Reputation colors | Unfriendly color | `OdysseusDB.xpBar.repColors.unfriendly`. | OUS2 has an Unfriendly standing color picker. | Present | None. | Implemented; preserves nested table shape. |
| Reputation colors | Neutral color | `OdysseusDB.xpBar.repColors.neutral`. | OUS2 has a Neutral standing color picker. | Present | None. | Implemented; preserves nested table shape. |
| Reputation colors | Friendly color | `OdysseusDB.xpBar.repColors.friendly`. | OUS2 has a Friendly standing color picker. | Present | None. | Implemented; preserves nested table shape. |
| Reputation colors | Honored color | `OdysseusDB.xpBar.repColors.honored`. | OUS2 has a Honored standing color picker. | Present | None. | Implemented; preserves nested table shape. |
| Reputation colors | Revered color | `OdysseusDB.xpBar.repColors.revered`. | OUS2 has a Revered standing color picker. | Present | None. | Implemented; preserves nested table shape. |
| Reputation colors | Exalted color | `OdysseusDB.xpBar.repColors.exalted`. | OUS2 has an Exalted standing color picker. | Present | None. | Implemented; preserves nested table shape. |
| Reputation colors | Renown color | `OdysseusDB.xpBar.repColors.renown`. | OUS2 has a Renown standing color picker. | Present | None. | Implemented; verify major faction display. |
| Reputation colors | Paragon color | `OdysseusDB.xpBar.repColors.paragon`. | OUS2 has a Paragon standing color picker. | Present | None. | Implemented; verify reward-ready display still shows reward icon. |
| Reputation bar settings | Enable Renown and Paragon Reward Popups | `OdysseusDB.xpBar.toastEnabled`. | OUS2 has `Toast Enabled`. | Present | None. | Label differs but behavior is covered. |
| Reputation bar settings | Play Sound on Reward Popup | `OdysseusDB.xpBar.toastSound`. | OUS2 has `Toast Sound`. | Present | None. | No sound picker exists in legacy. |
| Favorites | Right-Click Modifier for Faction Menu | `OdysseusDB.xpBar.repMenuMod`; legacy cycle button over CTRL, SHIFT, ALT, NONE. | OUS2 has explicit CTRL/SHIFT/ALT/NONE selection buttons. | Present | None. | Intentional OUS2 improvement. |
| Reset defaults | Reputation Reset Defaults | Legacy resets `repTemplate`, `repTextColor`, `repColors`, `toastEnabled`, `toastSound`, and `repMenuMod`; calls `OUS.UpdateBar()`. | OUS2 has a Reputation `Reset Defaults` action for `repTemplate`, `repTextColor`, `repColors`, and `repMenuMod`; `toastEnabled` and `toastSound` are intentionally excluded pending final review. | Final review | Decide final toast reset scope before closing Phase 5.6. | Implemented for migration-approved keys; divergence is tracked in the Final Polish / Review List. |
| Favorites | Favorites selector help | Legacy help says modifier-right-click XP Bar opens faction menu. | OUS2 Favorites view documents existing selector. | Present | None. | Documentation-only parity is adequate until API exists. |
| Favorites | Favorites management UI | Legacy selector is in `xpbar_favorites.lua` and opens from modifier-right-click, not from `xpbar_config.lua`. Data stored in `OdysseusDB.xpBar.favFactions`. | OUS2 is read-only and does not open/manage the selector. | Partial | Add an OUS2 action to open the existing selector only if a public helper is exposed or can be safely introduced later. | Do not manipulate `favFactions` directly until a public selector API is planned. Recent combat guard means selector/hover behavior needs combat testing. |
| Delves | Companion Text Format | `OdysseusDB.xpBar.delveCompTemplate`; legacy commits on Enter and updates Delves bar. | OUS2 Delves page has `Companion Template`. | Present | None. | OUS2 commits on focus loss too. |
| Delves | Journey Text Format | `OdysseusDB.xpBar.delveJourTemplate`; legacy commits on Enter and updates Delves bar. | OUS2 Delves page has `Journey Template`. | Present | None. | Present. |
| Delves colors | Companion Color | `OdysseusDB.xpBar.delveCompColor`; legacy color picker and `OUS.UpdateDelveBar()`. | OUS2 has `Companion Color` picker. | Present | None. | Implemented; existing engine reads this in `OUS.UpdateDelveBar()`. |
| Delves colors | Journey Color | `OdysseusDB.xpBar.delveJourColor`; legacy color picker and `OUS.UpdateDelveBar()`. | OUS2 has `Journey Color` picker. | Present | None. | Implemented; existing engine reads this in `OUS.UpdateDelveBar()`. |
| Delves dimensions | Delve Bar Width | `OdysseusDB.xpBar.delveBarWidth`; legacy range 100-1000. | OUS2 has matching width range. | Present | None. | Verify after resize at default OUS2 size. |
| Delves dimensions | Delve Bar Height | `OdysseusDB.xpBar.delveBarHeight`; legacy range 20-100 step 2. | OUS2 has matching range and step. | Present | None. | Present. |
| Delves dimensions | Delve Bar Scale | `OdysseusDB.xpBar.delveBarScale`; legacy range 0.5-2.0. | OUS2 has matching range and step. | Present | None. | Present. |
| Delves position | Delve bar position reset | Legacy Delves reset restores `OdysseusDB.xpBar.delveBarPos` and reanchors `OUS.delveBarFrame`. | OUS2 has no Delves reset action. | Missing | Add Delves reset action after Delves colors. | This is reset parity, not a separate position control. |
| Reset defaults | Delves Reset Defaults | Resets Delves templates, colors, dimensions, scale, and position; applies dimensions, wake/update/sleep. | OUS2 has no Delves reset. | Missing | Add Delves reset action. | Keep scoped to Delves keys only. |
| Help | XP template token help | Legacy Help tab lists XP tokens. | OUS2 XPBar Help lists XP tokens. | Present | None. | OUS2 includes additional `needRep` style tokens. |
| Help | Reputation and Delves token help | Legacy Help tab lists rep and Delves tokens. | OUS2 XPBar Help lists reputation and Delves tokens. | Present | None. | OUS2 help is more complete. |
| Help | Master chat commands | Legacy Help tab lists `/ous`, `/ous help`, `/xpstats`, `/toasttest`, and movement tips. | OUS2 XPBar Help lists `/xpstats`, `/toasttest`, movement, favorites, and notes. | Partial | Optional text review only. | Add `/ous` and `/ous help` only if XPBar Help is intended to fully mirror legacy tab. Addon-wide Help already covers global commands. |
| Blizzard UI hiding reload behavior | Reload prompt | Legacy popup asks "Reload now?" with Yes/No. | OUS2 popup says reload is required and offers Reload UI/Later. | Intentional difference | None, unless exact wording parity is desired. | Behavior is equivalent. |
| Blizzard UI hiding reload behavior | Instance guard | Legacy disables Hide Blizzard checkbox when `IsInInstance()` returns true. | OUS2 does not appear to disable the row in instances. | Behavior audit | Audit whether disabling is still needed in Retail 12.0+ and whether OUS2 can express disabled rows. | Avoid changing this until in-game behavior is understood. |
| Dimensions | XP bar position movement | Legacy help says Shift-drag XP Bar. Position saved by `xpbar_core.lua`. | OUS2 Help documents Shift-drag movement. | Present | None. | No OUS2 position reset exists for XP Bar. Legacy XP tab does not reset XP bar position. |
| Delves lock/unlock | Shift-drag Delves movement | Legacy has Shift-drag movement and reset through Delves reset. No explicit lock checkbox in legacy XP config. | OUS2 documents Shift-drag movement. | Behavior audit | Do not add lock/unlock until separate behavior review confirms a desired DB key and runtime contract. | This is not direct legacy parity unless a legacy lock state exists elsewhere. |

## 5. Suggested Patch Order

Do not implement the remaining work as one large patch. Completed implementation patches:

1. XPBar Global range/media/border patch:
   * Font, border style, border color, border size, and documented Global numeric range parity are implemented.
2. XPBar Experience color patch:
   * XP, XP text, rested, and background color controls are implemented.
3. XPBar Reputation color patch:
   * Reputation text color and standing color grid are implemented.
4. XPBar section reset patch:
   * Global, Experience, and Reputation Reset Defaults actions are implemented.
   * Reputation reset toast scope remains a final-review item.
5. Delves color patch:
   * Companion and journey color controls are implemented.

Remaining recommended small patches:

1. Delves reset patch:
   * Add Delves Reset Defaults with position reset parity.
2. Favorites API planning patch:
   * Document or expose a small public helper for the existing selector only if needed.
   * Then add an OUS2 action to open the selector.
3. Blizzard hide behavior audit:
   * Decide whether OUS2 should disable Hide Blizzard XP/Rep Bars while in an instance.
4. Final polish/review pass:
   * Resolve `showRestIcon` placement, Reputation toast reset scope, live-preview consistency, popup layering, and helper extraction timing.

## 6. Reset Semantics Review

Legacy reset is tab-scoped, not a single XP Bar reset:

* Global reset touches shared behavior, fonts, borders, auto-hide, opacity, and Blizzard hiding.
* Experience reset touches XP template, XP/rest/background/text colors, rested icon, and XP dimensions.
* Reputation reset touches rep template, rep text color, rep standing colors, toast settings, and menu modifier.
* Delves reset touches Delves templates, colors, dimensions, scale, and Delves position.

OUS2 should keep these as section-specific actions rather than adding one broad XP Bar reset in the first parity pass.

Uncertainty:

* OUS2 Experience reset calls existing public helpers so the UI and live bars refresh immediately. Final review should verify this is the desired OUS2 standard despite the legacy reset only visibly calling `OUS.ApplyXPBarBg()`.
* OUS2 Reputation reset currently excludes `toastEnabled` and `toastSound` because the migration scope explicitly excluded Toast settings. Final review must decide whether to restore legacy reset behavior or document the narrower OUS2 reset scope as standard.
* Shell-level OUS2 Reset to Defaults is broader than legacy XP tab resets and should not be used as the parity mechanism.

## 7. Combat / Runtime Safety Notes

* The favorites hover dashboard is runtime UI, not OUS2 configuration. It now has a combat guard in `xpbar_favorites.lua` to avoid opening during combat.
* Do not create, reposition, or refresh favorites popup UI from OUS2 during combat unless a future public helper handles that guard.
* `OUS.SleepBars()` already avoids fading while `UnitAffectingCombat("player")` is true.
* XP/Rep rendering uses live player, reputation, and Delves APIs. OUS2 controls should only write existing DB keys and call established public helpers such as `OUS.UpdateBar()`, `OUS.UpdateDelveBar()`, `OUS.ApplyFonts()`, `OUS.ApplyDimensions()`, `OUS.ApplyXPBarBg()`, and `OUS.ApplyXPBarBorders()`.
* Avoid adding direct calls to protected Blizzard frame mutation in OUS2. Blizzard XP/Rep hiding remains owned by `OUS.ApplyBlizzardKiller()`.

## 8. Frame Strata / Popup Notes

* Legacy font and border dropdowns use legacy config dropdown helpers. OUS2 should use `C.OpenMediaDropdown()` so dropdowns appear above the OUS2 frame.
* OUS2 color controls should use `C.OpenColorPicker()` and existing color swatch patterns.
* OUS2 copy/dialog style is not needed for XP Bar parity unless future template import/export is added.
* Favorites selector frame is `OdysseusFactionSelectFrame` at `DIALOG` strata and is currently opened from modifier-right-click on the XP Bar. If OUS2 later opens it directly, verify it appears above OUS2 and does not open in combat.
* Toast frame and session stats frame are runtime frames and should not be reparented or restyled from OUS2 parity patches.

## 9. Final Polish / Review List

This is a future polish checklist, not active implementation work for the current parity patches.

* Review whether `showRestIcon` should remain in OUS2 Global or move to Experience, because legacy reset treats it as Experience scope.
* Review all XP Bar controls for section placement: Global, Experience, Reputation, and Delves.
* Final alignment polish for newly added Global media, color, and border rows.
* Final alignment polish for Experience and Reputation color rows.
* Verify all ColorPicker frames open above OUS2.
* Verify all reset buttons refresh the visible widgets and live bars.
* Verify reset scopes match legacy exactly.
* Keep completed/remaining status current after the Delves reset patch and final XP Bar review decisions are done.
* Consider extracting duplicated OUS2 color, media, and action row helpers later into a shared helper file, but only after parity is complete.
* Do not refactor helper duplication during XP parity patches.
* Live Preview Consistency:
  * Verify every visual XP Bar setting updates immediately where legacy `/ous` does.
  * Review font changes, border style/color/size, Experience colors, Reputation colors, Delves colors, dimensions, scale, and template changes.
  * Confirm `/reload` is only required where Blizzard APIs inherently require it, such as Hide Blizzard XP/Rep Bar.
* Navigation Consistency:
  * Verify all OUS2 navigation paths resolve to the correct page: General dashboard cards, left navigation buttons, XP Bar hub child cards, and Back buttons.
  * Confirm page keys remain synchronized after future additions.
* Reputation Reset Scope Review:
  * Review legacy Reputation Reset handling for `toastEnabled` and `toastSound`.
  * Current OUS2 implementation intentionally excludes both settings because the migration scope explicitly excluded Toast settings.
  * Decide during the final XP Bar parity review whether legacy behavior should be restored or the new behavior should become the documented OUS2 standard.
  * Document the final decision before closing Phase 5.6.

## 10. Testing Checklist

Global:

* `/reload`
* Open `/ous` XP Bar tab and record current legacy values.
* Open `/ous2` -> XP Bar -> Global and confirm all values match.
* Toggle XP Bar module off/on and confirm XP and Delves frames hide/show safely.
* Toggle Hide Blizzard XP/Rep Bars and confirm reload prompt.
* Test Hide Blizzard setting while in an instance if OUS2 adds the legacy disabled state.
* Toggle auto-hide and verify wake/sleep behavior.
* Test rep display time, fade delay, active alpha, and faded alpha.
* Change font and font size, then verify XP and Delves text update.
* Change border style/color/size and verify XP and Delves border updates.

Experience:

* Change XP template and confirm Enter and focus-loss commit paths.
* Change XP, rested, background, and text colors.
* Change XP width, height, and scale.
* Toggle rested icon.
* Reset Experience defaults and verify legacy `/ous` shows matching values.

Reputation:

* Change reputation template.
* Change rep text color and all standing colors.
* Test watched faction display at max level.
* Test renown display.
* Test paragon display and reward icon state.
* Toggle toast enabled and toast sound.
* Test `/toasttest`.
* Change faction menu modifier and verify modifier-right-click opens the selector.
* Reset Reputation defaults and verify legacy `/ous` shows matching values.

Favorites:

* Open selector out of combat.
* Save favorite factions and verify `OdysseusDB.xpBar.favFactions`.
* Confirm OUS2 Favorites view remains accurate.
* Enter combat and verify favorites hover popup does not open.
* If OUS2 later opens the selector, verify it does not open during combat and appears above OUS2 out of combat.

Delves:

* Change companion and journey templates.
* Change companion and journey colors.
* Change Delves width, height, and scale.
* Shift-drag Delves bar and confirm saved position.
* Reset Delves defaults and verify dimensions, colors, templates, scale, and position.
* Test Delves page Back to XP Bar.
* Test entering/leaving a Delve or `/delvetest` where appropriate.

General verification:

* Run `luacheck` on changed files for each implementation patch.
* Run `git diff --check`.
* Confirm no Lua errors.
* Confirm no SavedVariables structure changes.
* Confirm no BuffBars files or TOC entries are touched.

## 11. Completion Criteria

XP Bar OUS2 parity is complete when:

* Every legacy `xpbar_config.lua` setting is either present in OUS2, explicitly marked as an intentional difference, or documented as owned by runtime UI rather than configuration.
* OUS2 writes only existing `OdysseusDB.xpBar` and `OdysseusDB.modules.xpBar` keys.
* OUS2 uses existing public runtime helpers for applying settings.
* Global, Experience, Reputation, and Delves reset scopes match legacy behavior or have a documented behavior-audit decision.
* Font, border, color, dimension, template, fade, toast, and modifier controls are usable from OUS2.
* Favorites management has either a safe OUS2 action using an existing/public helper or remains explicitly read-only with documented rationale.
* In-game testing confirms `/ous` and `/ous2` reflect the same values after changes and `/reload`.
* No Lua errors occur in normal use, combat hover, Delves transitions, max-level reputation display, or reset flows.

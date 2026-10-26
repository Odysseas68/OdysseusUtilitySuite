# Junk Seller Coin Animation — Retail API Research

Research recorded: **2026-10-26**. Current status: **OUS-UTILITIES-VENDOR-001 COMPLETE — IMPLEMENTED — RUNTIME TESTED (bounded user acceptance).**

Sections 1–12 preserve the original pre-implementation research. Section 13 records subsequent user-reported prototype results and the production implementation; Section 14 records final user-reported WoW acceptance and closure. These sections supersede earlier proposal/status statements where explicitly noted.

## 1. Purpose and Scope

Investigate a small animated gold coin to the right of a stationary **Selling** label on the Midnight-themed OUS Junk Seller vendor button. The coin must occupy a fixed layout region; the live remaining-entry count stays on the second line. The desired effect resembles a coin turning around its own vertical axis, rather than ordinary rotation in the screen plane.

The user has approved the existing button appearance and placement in WoW. That observation does not verify an animation or every selling transition. This document preserves the completed read-only research; it does not authorize or implement changes to presentation, visibility, selling behavior, settings or assets.

Evidence labels used below:

- **Verified source fact:** established by the inspected OUS or Blizzard snapshot.
- **Recommendation:** proposed architecture or prototype design, not implemented behavior.
- **Visual expectation:** an assessment requiring a WoW visual test.
- **Pending runtime validation:** behavior or performance not established by static source inspection.

## 2. Blizzard Source Baseline

| Property | Inspected value |
| --- | --- |
| Local source | `D:\WowDEV\Reference\Blizzard\wow-ui-source` |
| Branch | `live` |
| Commit | `15881d522c44cd106d3d8660106ec9f9d2f44167` |
| Retail build | `12.1.5.70575` (`version.txt:1`; commit subject `12.1.5 (70575)`) |

**Verified against this source snapshot, not every earlier Retail 12.x build.** No PTR or beta findings are being substituted for LIVE evidence. Generated API contracts establish exposed methods and signatures; Blizzard Lua/XML establishes concrete usage. Neither proves the appearance, performance or taint behavior of a future OUS implementation in the running client.

All Blizzard references below are relative to the local source root above. Line numbers identify the inspected snapshot and may change after a source update. No new API or visual runtime experiments were performed for this document.

## 3. Verified Retail Animation Facilities

The following paths are under `Interface/AddOns/` in the Blizzard source root.

| Facility | Verified contract or usage | Source reference |
| --- | --- | --- |
| Animation group creation | `CreateAnimationGroup(name, templateName)` returns an animation group. | `Blizzard_APIDocumentationGenerated/SimpleAnimatableObjectAPIDocumentation.lua:10–22` |
| Animation creation | Group `CreateAnimation(animationType, name, templateName)` returns an animation. Creation checks the `AddAnimations` forbidden aspect; this is not permission to animate arbitrary Blizzard regions. | `Blizzard_APIDocumentationGenerated/SimpleAnimGroupAPIDocumentation.lua:10–24` |
| Playback and looping | Group `Play(reverse, offset)`, `Stop()`, `IsPlaying()`, `Restart()` and `SetLooping(loopType)` are exposed. XML defines `NONE`, `REPEAT` and `BOUNCE`. | `Blizzard_APIDocumentationGenerated/SimpleAnimGroupAPIDocumentation.lua:227, 276, 295, 316, 359`; `Blizzard_SharedXML/UI.xsd:1494–1499` |
| Callbacks | Animation-group scripts include `OnPlay`, `OnPause`, `OnStop`, `OnUpdate`, `OnFinished` and `OnLoop`. These are presentation hooks, not a reason to place vendor actions in animation callbacks. | `Blizzard_SharedXML/UI.xsd:1539–1548`; `Blizzard_APIDocumentationGenerated/SimpleAnimGroupAPIDocumentation.lua:336–345` |
| Rotation | Rotation exposes degrees/radians and an origin consisting of a frame point plus X/Y offsets. No three-dimensional rotation-axis parameter is exposed here. | `Blizzard_APIDocumentationGenerated/SimpleAnimRotationAPIDocumentation.lua:51–79`; `Blizzard_SharedXML/UI.xsd:1607–1615` |
| Independent X/Y Scale | `SetOrigin(point, originX, originY)`, `SetScaleFrom(scaleX, scaleY)` and `SetScaleTo(scaleX, scaleY)` allow horizontal changes while leaving vertical scale unchanged. | `Blizzard_APIDocumentationGenerated/SimpleAnimScaleAPIDocumentation.lua:67–108`; `Blizzard_SharedXML/UI.xsd:1617–1629` |
| Alpha and Translation | Native fades and X/Y translation can be combined with scaling. Blizzard animates a gem glow and moves a sheen in successive orders. | `Blizzard_UIWidgets/Blizzard_UIWidgetAnimationTemplates.xml:38–45` |
| Texture-coordinate translation | Native `TextureCoordTranslation` shifts U/V coordinates. Blizzard repeats this on the four edges of Marching Ants. It scrolls texture sampling; it does not create a coin's reverse face or depth. | `Blizzard_SharedXML/MarchingAnts.xml:50–55`; `Blizzard_SharedXML/UI.xsd:1709–1717` |
| Lua sprite-coordinate advancement | `TextureUtil.AnimateTexCoords(texture, textureWidth, textureHeight, frameWidth, frameHeight, numFrames, elapsed, throttle)` advances sprite cells using elapsed time and `SetTexCoord`. It needs update driving from its caller. | `Blizzard_SharedXMLBase/TextureUtil.lua:28–58` |
| Native FlipBook | Dedicated FlipBook setters expose rows, columns, frames and frame dimensions. Blizzard loops 20 supplied frames over 1.2 seconds. | `Blizzard_APIDocumentationGenerated/SimpleAnimFlipBookAPIDocumentation.lua:75–121`; `Blizzard_UIWidgets/Blizzard_UIWidgetTemplateFillUpFrames.xml:81–83` |
| Texture transforms | Texture `SetRotation(radians, normalizedRotationPoint)` has a two-dimensional rotation point; vertex offsets expose X/Y. `SetTexCoord` and `SetSpriteSheetCell` support sampling changes, not real three-dimensional lighting or geometry. | `Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua:527–590, 657–665` |

Concrete lifecycle and visual examples:

- **Continuous rotation:** `Blizzard_SharedXML/Spinner.xml:12–18` uses a repeating group with centered `-360` degree Rotation animations. `Blizzard_SharedXML/Spinner.lua:4–17` restarts on show and stops on hide.
- **Horizontal scaling:** `Blizzard_FrameXMLBase/AnimatedStatusBar.xml:77–78` scales X from `0.001` to `1`, holding Y at `1`. Its origin is LEFT; a coin prototype would deliberately choose CENTER instead.
- **Repeated opacity pulse:** `Blizzard_UIWidgets/Blizzard_UIWidgetTemplateFillUpFrames.xml:42–45` repeats fade-in/fade-out phases. A repeating horizontal squeeze is a proposed combination of verified Scale and looping facilities, not a discovered Blizzard coin-flip implementation.
- **Sprite lifecycle:** `Blizzard_UIWidgets/Blizzard_UIWidgetTemplateFillUpFrames.lua:210–214, 268–282` checks atlas availability, assigns artwork, then shows/plays or hides/stops the native FlipBook.
- **Explicit hide cleanup:** `Blizzard_SharedXML/AnimationTemplates.xml:42–47` wires animation play/stop to frame show/hide; `Blizzard_SharedXML/AnimationTemplates.lua:85–98` implements those operations.

The focused money, currency and shared-animation source inspection did not establish a ready-made spinning gold-coin animation. This is a bounded search result, not proof that no suitable artwork exists anywhere in the client.

## 4. Three-Dimensional Rotation Limitation

**Verified source fact:** the inspected standard Texture Rotation API provides screen-plane rotation. It does not expose genuine Y-axis three-dimensional rotation. Texture vertex offsets and texture-coordinate manipulation can reshape or resample a flat image, but do not supply a reverse face, coin thickness or changing illumination.

Model/ModelScene is a different rendering route. For example, `Blizzard_APIDocumentationGenerated/SimpleModelAPIDocumentation.lua:698–706` exposes `SetTransform` with three-dimensional translation and rotation vectors. A model solution would require a suitable model asset and additional camera, orientation, lighting and lifecycle work; this research did not select or validate such a model.

**Recommendation:** prefer a flat-image simulation or prerecorded frames for a 14–18px indicator. The expected benefit of actual model rendering is small at that size, while implementation and asset requirements are substantially greater. This is an architectural assessment, not a measured comparison.

## 5. Technique Comparison

Visual-quality and overhead assessments are expectations, not WoW runtime results.

| Technique | Visual fidelity at 14–18px | Complexity, overhead and maintenance | Evidence limits |
| --- | --- | --- | --- |
| A. Native centered horizontal Scale | Squash/expand can suggest a vertical-axis turn. One image cannot show a distinct reverse face or genuine changing light. | One texture and native group; no Lua per-frame loop is needed. Smallest prototype and simplest lifecycle. | Exact easing, minimum width and edge-on appearance need testing. |
| B. Native FlipBook with prepared sprite sheet | Best prospect for convincing edge, reverse-face and highlight changes in a fixed region. | Native frame playback; maintain artwork plus rows, columns, frame count and duration. No per-item animation allocation is needed. | Requires a real suitable sprite sheet. FlipBook does not generate new views from one static coin. |
| C. Manual width or UV animation | Can simulate a squeeze or step through supplied frames. | Requires custom update/reset management. Width animation must keep a stable center; packed-atlas UV bounds must be preserved. More Lua lifecycle work than native alternatives. | Supported primitives do not establish a convincing result or better performance. |
| D. Rotation, pulse or shimmer | Recognizable activity indicator, but ordinary rotation is not the requested vertical-axis flip. | Native groups are straightforward. A shimmer may add a separate texture/mask. | Legibility and visual distraction require review. |
| E. Model/ModelScene | Could provide actual three-dimensional rendering with suitable assets. | More asset, camera, lighting and playback setup; greater maintenance burden for a tiny control. | No model candidate, runtime behavior or performance was verified. |

All approaches can keep text stationary if animation targets only the coin region. No approach should resize or animate the text row or the whole Junk Seller button.

## 6. Verified Coin Artwork

**Verified candidate: Blizzard atlas `coin-gold`.**

- `Interface/AddOns/Blizzard_MoneyFrame/Shared/MoneyFrame.lua:347–353` maps Gold and AuctionHouseGold displays to `coin-gold`.
- The same file at `383–394` assigns the atlas and sets its icon size to **12×14**.
- `Interface/AddOns/Blizzard_FrameXML/Mainline/CoinPickupFrame.xml:13` directly declares a gold texture with that atlas.

Suggested initial artwork assignment: `coinTexture:SetAtlas("coin-gold")`. This is an implementation proposal using a verified atlas name, not code already added to OUS. No standalone coin FileDataID, standalone path or animation sprite sheet was verified. The user may select different artwork through wow.export.

Optional in-game inspection command, **not executed during this research**:

```lua
/run local a=C_Texture.GetAtlasInfo("coin-gold"); if a then print(a.file,a.filename,a.width,a.height,a.leftTexCoord,a.rightTexCoord,a.topTexCoord,a.bottomTexCoord) end
```

`Interface/AddOns/Blizzard_APIDocumentationGenerated/TextureUtilsDocumentation.lua:75–87` states that `GetAtlasInfo` may return nothing. Its `AtlasInfo` structure at `204–220` includes dimensions and UV bounds, with potentially absent `file` and `filename` fields. A backing file may contain multiple atlas elements: displaying that entire file without the correct UV bounds is not equivalent to using `SetAtlas("coin-gold")`.

## 7. Recommended Prototype

**Recommendation, not implemented:** begin with an isolated, disposable WoW runtime probe, separate from the merchant and transaction logic.

1. Show static **Selling** text and a fixed-size coin region immediately to its right. Start with a 14–16px coin and keep both layout anchors stationary.
2. Assign the verified `coin-gold` atlas.
3. Animate only the coin using native Scale with CENTER origin. Hold Y scale at `1`; squeeze X from `1` to a small positive minimum and expand it to `1` in a repeating cycle.
4. Do not depend on unverified zero/negative-scale behavior. Tune minimum X scale, duration and easing in WoW rather than treating a proposed value as a validated default.
5. Test start, several loops, explicit stop, reset to the normal face and subsequent restart. Verify that neither text nor the coin's center moves.
6. Test native FlipBook as an alternative when a suitable sprite sheet is found. Confirm its cell layout and frame metadata before relying on it.

Expected result: a lightweight flip illusion. Visual acceptability, edge-on flicker and texture filtering remain unknown until the probe runs in WoW. No probe was implemented or executed as part of this work.

## 8. Proposed OUS Integration

References below describe the inspected `Utilities.lua`, relative to the OUS addon root, not the Blizzard snapshot.

| Integration boundary | Existing source | Proposed responsibility |
| --- | --- | --- |
| One-time styling | `Utilities.lua:348`, `StyleJunkSellButton()` | Create the coin region and native group once. Reserve stable space to the right of Selling; leave count text on line two. |
| Presentation refresh | `Utilities.lua:409–420`, `OUS.UpdateJunkSellButton()` | Reconcile coin visibility and playback with the existing presentation state. Start only when appropriate and not already playing; do not restart at every count update. |
| Cancellation | `Utilities.lua:423–430`, `CancelJunkSelling()` | Existing cancellation clears active state and hides the button. An OUS-owned button `OnHide` should stop/reset the coin, including paths that hide directly without calling the refresh helper. |
| Queue/batch transitions | `Utilities.lua:440–539`, `SellNextItem()`; `542–558`, `SellNextBatch()` | Observe existing active/paused/completed state through presentation updates; do not alter queue processing or transactions. |
| Settings and merchant lifecycle | `Utilities.lua:561–568`, `OUS.ApplyJunkSellSettings()`; `572–604`, `OnMerchantShow()`; `938–954`, merchant/error dispatch | Preserve existing guards and cancellation. Reconcile animation after authorized state changes and stop it on closure, disablement or cancellation. |

Preserve the existing **120×38** Midnight button, media texture, border, fonts and merchant-relative placement:

```lua
junkSellBtn:SetPoint("TOPRIGHT", MerchantFrame, "BOTTOMRIGHT", -1, 1)
```

Preserve queue eligibility/blacklist filtering, remaining-entry count meaning, 12-entry batch boundaries, Require Shift checks, accounting/reporting, generation cancellation and the existing 0.3-second initial delay / 0.2-second continuations. Animation callbacks must never invoke a sale, advance the queue, change generations or restart selling.

**Verified OUS nuance:** `junkSaleActive` also covers the initial scheduled 0.3-second start (`Utilities.lua:595–603`). It identifies selling work, not confirmed vendor income; entries can also be skipped. A prototype must explicitly assess whether the coin should animate during that initial delay. A stricter active-transaction interpretation would need a separately reviewed presentation decision, not a silent change to selling semantics.

## 9. Future Visibility Requirement

**PROPOSED — NOT IMPLEMENTED.** When `MerchantFrame` is open and Utilities/Junk Seller are enabled, the button should eventually remain visible even when both Limit Sales to 12 and Require Shift are disabled. During active automatic selling it would serve as a Selling status display.

Current source still hides the button when both options are off (`Utilities.lua:412–415`). The proposed visibility change must be handled separately from selecting an animation technique. Idle and empty-queue presentation details remain design decisions.

The animation should run only during active selling work, not while waiting at a paused batch boundary or waiting for Shift confirmation. It must stop when the applicable activity ends even if a future visibility policy keeps the button visible.

## 10. Safety and Performance

- Reuse one coin region and native group. Do not allocate an animation for every sold entry or perform extra per-item bag scans.
- Prefer native Scale or FlipBook over Lua per-frame updates where they suffice. Avoid timers added solely for the indicator.
- Keep playback independent of the 0.2-second sale cadence. Repeated presentation refreshes must not restart the animation cycle.
- Keep every animation callback presentation-only. No callback may trigger vendor transactions, bypass Shift, resume a paused batch or reauthorize cancelled work.
- Animate only addon-owned regions using ordinary, non-secret presentation constants. Do not attach animations to protected Blizzard controls or change protected-action behavior. Generated forbidden-aspect/secret-argument annotations are not a blanket safety guarantee.
- Stop and reset on merchant close, seller/master disablement, cancellation and UI hide. Reset width/scale or sprite presentation as appropriate so a later display cannot begin stuck edge-on or at an arbitrary stale cell.
- Keep coin and text inside the established button bounds. Verify draw order relative to its face, hover/pressed textures and border; check parent clipping, scale and readability. Avoid an interactive coin region that intercepts the button's clicks.
- One reused native group is expected to have modest overhead during a 50+ entry sequence, but no performance benchmark, taint-safety certification or native lifecycle verification was performed.

## 11. Outstanding Runtime Verification

The isolated prototype and any later OUS integration require WoW checks for:

- `coin-gold` availability and visibility at 14–16px; evaluate 18px only if it fits without crowding either text line.
- Centered horizontal Scale appearance, stationary Selling text and unchanged count-line placement.
- Edge-on shimmer, flicker, filtering and minimum-width/easing choices.
- Smoothness during 50+ queued entries, without per-count animation restarts.
- Correct stop, reset and restart on completion, skipped entries and cancellation.
- Paused 12-entry batches and Require Shift confirmation: no activity animation while waiting, and no altered sale authorization.
- Utilities/seller disablement and rapid master off/on transitions: no animation or stale sale continuation revived.
- Merchant close/reopen, parent-frame hide and return to the correct initial presentation.
- Blizzard merchant UI and Krowi 2-column/4-column layouts, Merchant/Buyback tabs, Token Banner, scaling and clipping.
- Existing combat guards and absence of new taint/protected-action errors. Static inspection does not establish these native outcomes.

## 12. Current Status and Decision

**Source research is complete. No animation, visibility change, asset addition or runtime prototype has been implemented.** The existing Midnight button's visual approval is separate evidence.

Native centered horizontal Scale is the first disposable prototype candidate. Native FlipBook is preferred for richer coin-turning artwork when a suitable sprite sheet exists. Ordinary Rotation remains a screen-plane fallback, not a genuine Y-axis coin spin.

Visual quality, runtime overhead and lifecycle/taint behavior remain pending WoW verification. Future implementation should remain a presentation-only change, with the proposed both-options-off visibility policy reviewed explicitly.


## 13. Runtime Evidence and Production Integration — 2026-10-26

### User-reported prototype observations

These are user-reported native WoW observations, separate from source/API evidence and offline integration checks:

- **V1/V2:** the Blizzard gold atlas rendered and native horizontal Scale played. Both effects appeared similar to a half-turn/compress-expand cycle; changing the scale plumbing did not establish a convincing full spin.
- **V3:** `CoinSpin.tga` rendered, native FlipBook playback animated the coin, and Selling remained stationary. The successful artwork is preserved unchanged in the standalone probe.
- **V4:** the Goblin Counting native FlipBook was visually observed playing in WoW. The user selected **Goblin Counting Gold** as the production default. This observation does not independently establish every lifecycle transition, performance characteristic or production placement.

### Implemented production design

`Utilities.lua` reuses the successful native FlipBook technique with one OUS-owned frame, one texture, one animation group and one FlipBook. No Lua frame stepping, animation callbacks, new timers, per-item bag scans, media registrations or OdysseusShareMedia dependency were added.

| Choice | Production asset | Grid / frames | Cycle | Display |
| --- | --- | --- | --- | --- |
| Goblin Counting Gold — default | `media/Textures/GoblinCounting.tga` | 8×4 / 32 | 1.6 seconds | 28×28 |
| Spinning Coin | `media/Textures/CoinSpin.tga` | 4×4 / 16 | 1.2 seconds | 16×16 |

Both uncompressed 32-bit RGBA TGA files are byte-identical copies of the probe assets, respectively 512×256 and 256×256. Runtime paths are `Interface\AddOns\OdysseusUtilitySuite\media\Textures\GoblinCounting.tga` and `Interface\AddOns\OdysseusUtilitySuite\media\Textures\CoinSpin.tga`. The probe originals and Python generator remain research material; production does not load or depend on them. Goblin display is modestly enlarged from the tested 24px probe to 28px; the final production portrait was subsequently visually approved by the user (Section 14).

The final portrait is a **36×38 mouse-transparent child of MerchantFrame** (initial integration used 32×38 before portrait framing), with RIGHT anchored to the existing button's LEFT at **(-6, 0)**. It uses the button's frame strata and centers the selected artwork. Lua-created presentation layers provide dark charcoal/deep-purple backing, a slightly lighter inset two pixels inside the container, and a one-pixel purple border. The artwork is unchanged by this framing; the container dimensions are distinct from the 28×28 Goblin and 16×16 coin texture sizes. It is not a child of the button and does not follow the button's conditional visibility. The button's approved 120×38 size, exact TOPRIGHT-to-MerchantFrame-BOTTOMRIGHT anchor **(-1, 1)**, Midnight styling, fonts, labels and click handler are preserved.

### Persistent setting and OUS2 control

Account-wide selection is stored as `OdysseusDB.utilities.junkSell.animation`: **`"goblin"`** or **`"coin"`**. Utilities defaults and Core's existing database initialization provide Goblin for missing/invalid values without replacing other preferences. Rendering and the config label also fall back safely to Goblin. Existing reset-all handling already copies the Utilities defaults.

OUS2 Utilities has a themed **Junk Seller Animation** action selector, showing the current choice on a second line. Clicking alternates between the two named choices. It shares the existing action row with Manage Blacklist, keeping later controls at their original vertical positions. Its callback writes only the animation preference and calls `OUS.UpdateJunkSellAnimation()`; it never invokes the sale-settings transition or batch entry point.

### Visibility and playback contract

The artwork is visible while the merchant context is open and Utilities/Junk Seller are enabled, for **all four** Limit Sales to 12 / Require Shift combinations, including both off and no pending entries. The existing button still hides when both controls are off or its queue is empty. This independent artwork implements the current design; it does **not** implement Section 9's earlier proposal to keep the button itself visible.

- Running queued selling work plays the selected animation. Repeated count refreshes do not restart it.
- Scheduled initial start, waiting for Shift, paused batch boundary, combat-suppressed work and an empty queue show the first idle cell.
- A presentation-only scheduled-start flag distinguishes the existing 0.3-second delay from active work without changing sale authorization. The playback predicate also excludes the reached 12-entry boundary immediately after processing its last entry.
- Completion, cancellation, seller/master disablement and UI hide stop/reset playback. Merchant closure hides the frame; a mode change stops the old artwork and resumes the new one only if existing selling work is active.
- Enabling a feature after a merchant has already opened can create/show idle artwork. It does not rescan bags or resume cancelled work.
- Frame creation is lazy and reused. The existing button-creation block is shared by presentation setup without changing its geometry or click handler. Existing generation cancellation, eligibility/blacklist filtering, Shift confirmation, batching, pricing, reporting/accounting and 0.2-second continuation remain intact.

### Historical offline validation and original acceptance plan

Offline checks passed: Lua 5.1 syntax for Utilities, Core and the Utilities page; targeted LuaCheck **74 warnings / zero errors**, unchanged from baseline (Utilities 34, Core 40, page 0); **17/17 focused configuration/control-flow checks**; production asset metadata and byte equality; final scoped review and whitespace validation.

The deterministic checks include the actual OUS2 selector callback, isolated execution of Core's new setting migration, all four option combinations, invalid/missing fallback, idle/no-junk cases, active count refreshes, batch pauses, cancellation, close/reopen, parent hide/show, rapid disable/reenable, selection changes during a sale and animation reuse. A before/after Utilities comparison matched sale counts, accounting inputs and timer-delay sequences across all four option combinations. Mocks do not reproduce native rendering, protected-frame rules or third-party event ordering.

**Historical integration acceptance plan (before the Section 14 closure).** Test default Blizzard and Krowi 2/4-column Merchant/Buyback layouts with Token Banner visible; check left-side artwork clearance, window movement/resizing, scaling, clipping, layering and absence of intercepted clicks. Verify both choices and persistence after reload, all four option combinations, idle/no-junk display, Shift waiting, a 12-entry pause, completion, settings changes mid-sale, cancellation, seller/master toggles and merchant close/reopen. Confirm there are no taint/protected-action errors. Successful standalone V3/V4 playback does not establish these production outcomes.


## 14. Runtime Verification and Closure — 2026-10-26

**OUS-UTILITIES-VENDOR-001 — COMPLETE — IMPLEMENTED — RUNTIME TESTED.** Closure is based on the current implementation and the bounded native WoW observations reported by the user. It does not claim formal or exhaustive verification of the selling system.

### Final implementation confirmed against the local working tree

- **Button:** 120×38; `junkSellBtn:SetPoint("TOPRIGHT", MerchantFrame, "BOTTOMRIGHT", -1, 1)`. Dark charcoal-purple face, thin purple border, hover/pressed/disabled styling, and separate action/count lines remain intact.
- **Portrait:** separate 36×38 MerchantFrame child, anchored RIGHT to the button's LEFT at (-6, 0), mouse-transparent, with Midnight backing, lighter inset and one-pixel purple border. Goblin display remains 28×28; coin display 16×16. Neither TGA was changed by portrait styling.
- **Selection:** `OdysseusDB.utilities.junkSell.animation`, allowed values `"goblin"` and `"coin"`, default `"goblin"`. The OUS2 Utilities selector changes presentation only; missing/invalid values fall back to Goblin. Asset locations, grids and timing remain as recorded in Section 13.
- **Source visibility/playback contract:** with the merchant open and Utilities/Junk Seller enabled, the portrait is independent of both selling options and button visibility. Idle/no-junk, scheduled start, Shift waiting and batch pause show the first frame; active queued selling plays; completion/pause stops and resets; merchant closure hides the portrait. This is verified source behavior. The observations below do not independently document every option combination or event ordering.

### User-observed native WoW results

These observations were supplied by the user; they are not automated tests or deductions from mocked execution.

| Area | Reported observation | Evidence boundary |
| --- | --- | --- |
| Midnight button | Appearance and final placement visually approved in WoW. | Does not establish every merchant layout or scale. |
| Framed Goblin portrait | Visually approved after Midnight framing was added. | Approval concerns the displayed production portrait, not a change to the artwork dimensions. |
| Idle | Goblin remains stationary while waiting. | Bounded observed idle behavior. |
| Active selling and completion | Goblin animates while junk is sold, then returns to idle. | Does not establish all cancellation or combat sequences. |
| Remaining-entry counter | Updates correctly during selling. | Counter represents queued entries, not total physical stack quantity. |
| Limit Sales to 12 | 12-entry batch behavior works, including continuation. | Does not establish every mid-batch option permutation. |
| Require Shift | Holding Shift while opening the merchant authorizes selling as intended. | Other possible Shift interactions were not exhaustively tested. |
| Animation selection | Switching between the animations works. | Presentation selection observed; no broader transaction claim is inferred. |
| Persistence | Selected animation survives `/reload`. | Explicitly reported persistence result. |
| Merchant close during selling | Test started with **19 individual items across 12 bag slots**. Escape closed the merchant and stopped the sale; reopening allowed remaining junk to be sold. | Observed behavior is consistent with intended cancellation/reopen handling. It is not direct internal proof of generation invalidation. Physical item quantity and queued slot-entry count are distinct. |
| Standalone V3 | Spinning coin rendered and animated in WoW. | Standalone probe result, separate from production integration. |
| Standalone V4 | Goblin Counting Gold rendered and animated in WoW. | Standalone probe result, separate from production integration. |

### Offline evidence and remaining untested cases

Previously reported Codex offline validation remains separate evidence: positioning-phase 36/36 checks; integration-phase 17/17 checks with LuaCheck 74 warnings / zero errors across Utilities/Core/page; portrait-phase 18/18 checks with Utilities LuaCheck 34 warnings / zero errors; Lua 5.1 syntax and whitespace checks passed at those implementation handoffs. These historical checks were not rerun or converted into native WoW results by this documentation-only closeout. Source/API findings remain tied to Retail **12.1.5.70575**, commit **15881d522c44cd106d3d8660106ec9f9d2f44167**.

Not directly runtime tested for this enhancement:

- Disabling Utilities while a sale is in progress.
- Exhaustive rapid-toggle and cancellation permutations.
- Every Blizzard/Krowi merchant layout combination.
- Exhaustive taint/combat behavior.

These remaining cases do **not** block closure of the current Junk Seller UI enhancement. Preserve their untested status for future regression testing. In particular, neither observed Escape-close cancellation nor successful offline generation checks proves every possible stale-callback ordering in the native client.

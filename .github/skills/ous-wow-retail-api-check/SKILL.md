---
name: ous-wow-retail-api-check
description: Verify unfamiliar or uncertain World of Warcraft Retail 12.0+ APIs before changing Odysseus Utility Suite. Use for event handlers, protected UI interactions, secret values, or aura, spell, unit, stats, map, scenario, delve, XP, reputation, flight, item, mount, pet, toy, and frame APIs when signatures, payloads, return values, nil cases, or restrictions matter.
---

# OUS WoW Retail API Check

1. Read `AGENTS.md`, inspect the directly relevant working OUS path, and use `$ous-reference-workspace` when local source verification is needed. Do not require Blizzard Research-only skills that are absent from this checkout.
2. Keep evidence categories explicit: documented API contracts, verified OUS behavior, verified Blizzard implementation/source facts (with LIVE/PTR provenance), verified runtime observations, documented compatibility behavior, source-supported inference, and assumptions.
3. Prefer established working OUS behavior unless the task requires a change. A different Blizzard implementation pattern is evidence, not automatic reason to replace stable OUS code.
4. For API-sensitive production work, verify against the current LIVE Retail source and generated API docs configured by the repository. Keep PTR findings labeled and separate; do not promote them to LIVE facts without matching evidence.
5. Confirm the symbol exists in the target context and verify arguments, returns, event payloads, nil or delayed-loading behavior, secret predicates, combat-lockdown risk, and taint boundaries as relevant.
6. Check namespaced and legacy symbols independently. Prefer the current native API, but do not infer that a global is deprecated or unavailable merely because a `C_` alternative exists; distinguish retained globals and compatibility aliases from obsolete APIs.
7. For restricted UI paths, prefer direct anchors and layout relationships over unnecessary Lua-side geometry reads or arithmetic. Do not blanket-ban `BackdropTemplate`, frame geometry, or tooltip APIs; verify the specific frame and combat context.
8. When an asynchronous failure surfaces in a Blizzard dispatcher, trace callback registration and ownership before assigning root cause. Treat the dispatcher line and feature-level correlation as evidence, not attribution.
9. Never infer Retail signatures from Classic examples, stale source snapshots, or model memory. If the configured LIVE source cannot be established, report that uncertainty before editing.

Report the target client/source checked, verified signature or behavior, evidence category, nil/combat/taint/secret-value risks, and recommended usage.

## Conditional Blizzard Lua/XML Source Walk

Apply this source walk only when an OUS implementation, bug investigation, compatibility decision, or technical conclusion materially depends on Blizzard UI/FrameXML implementation behavior. Ordinary addon implementation, configuration work, documentation maintenance, and unrelated API usage do not require XML investigation.

- Do not assume a `.lua` file contains the complete implementation. Check relevant associated `.xml` files when XML templates or scripts may participate in the behavior.
- Trace behavior bidirectionally where applicable: Lua -> XML templates, inherited templates, `Scripts` blocks, handlers (`OnLoad`, `OnShow`, `OnClick`, `OnEvent`), and bindings; XML -> Lua functions, callbacks, events, and APIs invoked by those templates or handlers.
- Read enough surrounding source to understand control flow; search hits alone are insufficient.
- Inspect relevant nearby Blizzard developer comments, especially `FIXME`, `TODO`, implementation notes, and comments directly associated with the behavior. Report comments separately, interpret only what their literal wording supports, and never treat them as proof of runtime behavior.
- If no relevant XML exists, record that fact when it matters to the research conclusion. Keep the evidence categories above distinct throughout the conclusion.

## Requested Audits of Existing Research

Only when specifically asked to audit existing OUS technical/research documentation against additional Blizzard Lua/XML source:

- Preserve the existing document as the baseline; do not rewrite, reorganize, modernize, or stylistically clean up working research.
- Classify newly found evidence as **Confirmed**, **Additional context**, **Omission**, or **Correction required**.
- Make only narrowly justified additive or corrective changes within the authorized scope.
- Preserve historical runtime observations and controlled-test evidence unless new evidence specifically invalidates their interpretation.

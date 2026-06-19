---
name: ous-wow-retail-api-check
description: Verify unfamiliar or uncertain World of Warcraft Retail 12.0+ APIs before changing Odysseus Utility Suite. Use for event handlers, protected UI interactions, secret values, or aura, spell, unit, stats, map, scenario, delve, XP, reputation, flight, item, mount, pet, toy, and frame APIs when signatures, payloads, return values, nil cases, or restrictions matter.
---

# OUS WoW Retail API Check

1. Read `AGENTS.md` and the relevant project-local `wow-api-*` or `wow-addon-structure` skills.
2. Verify in order: project instructions, local `WoWAddonDevGuide`, the live `wow-ui-source`, generated Blizzard API docs, then `EnhanceQoL` as a modern comparison.
3. Confirm the exact function name, arguments, returns, event payload, nil or delayed-loading behavior, combat-lockdown and taint risk, and secret predicates.
4. Prefer the modern Retail-safe `C_` namespace when the verified API uses it.
5. Never infer from Classic examples, old addon code, or memory.
6. Call out unresolved uncertainty before editing.

Report the verified API, sources checked, signature and returns, risks, and recommended usage.

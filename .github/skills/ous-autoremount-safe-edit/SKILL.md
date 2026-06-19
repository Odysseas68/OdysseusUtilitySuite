---
name: ous-autoremount-safe-edit
description: Safely edit OUS AutoRemount logic or its spell database. Use for AutoRemount.lua or AutoRemountSpells.lua when gather and exclusion lists, forms, mounts, combat, crafting or profession exclusions, spy mode, or protected actions are involved.
---

# OUS AutoRemount Safe Edit

1. Read `AGENTS.md` and inspect the existing event and exclusion flow.
2. Preserve the keyed spell database style and the separation between gather and exclusion lists.
3. Check combat, current form, mounting state, profession crafting, and other established exclusions before changing behavior.
4. Do not introduce protected mount or form calls in unsafe contexts.
5. Keep spy and debug modes from producing routine chat spam; use `OUS.LogDebug` for debug output.
6. Preserve current SavedVariables and public function names.
7. Verify mount, spell, form, profession, and combat APIs with `$ous-wow-retail-api-check`.
8. Apply `$ous-minimal-addon-patch` constraints to the final edit.

Test combat entry and exit, gathering, excluded forms, crafting, mounted state, and spy mode as relevant.

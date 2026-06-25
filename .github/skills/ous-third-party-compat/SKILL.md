---
name: ous-third-party-compat
description: Use when Odysseus Utility Suite must coexist with another WoW addon, launcher/minimap display addon, or shared addon ecosystem library while preserving optional integration boundaries and OUS behavior.
---

# OUS Third-Party Addon Compatibility

Use this skill when OUS must coexist with another WoW addon or shared addon ecosystem library.

## Rules

1. Use WoW Retail 12.0+ APIs only.
2. Do not modify third-party addon files.
3. Prefer standard APIs and addon ecosystem libraries before addon-specific internals:
   - LibDataBroker-1.1
   - LibDBIcon-1.0
   - LibStub
   - CallbackHandler-1.0
   - Ace libraries only when already needed
4. Prefer ecosystem standards over addon-specific integrations.
5. Use LibDataBroker-1.1 + LibDBIcon-1.0 for minimap launchers instead of direct compatibility code.
6. Avoid calling third-party internal functions unless there is no supported alternative.
7. Do not write addon-specific workarounds when the observed behavior is shared by multiple addons.
8. Verify behavior against at least one additional well-known addon before classifying something as an OUS bug.
9. Keep optional integration guarded and load-order safe.
10. Preserve OUS behavior when the third-party addon is absent.
11. Avoid taint and protected calls.
12. Prefer event-driven or library-driven integration over polling.
13. Keep compatibility logic isolated.
14. Add concise one-line comments for integration boundaries.
15. Update documentation, TODO, changelog, and CLAUDE.md when compatibility behavior changes.
16. Prefer removing compatibility code over adding more compatibility code when a standards-based solution exists.

## Workflow

1. Reproduce the issue.
2. Determine whether the issue originates in OUS, a third-party addon, or a shared library.
3. Inspect the third-party addon's configuration, documentation, and user-facing options.
4. Inspect the third-party addon lifecycle and look for public APIs or ecosystem-standard integrations.
5. Verify the behavior with at least one additional mature addon implementing the same feature.
6. If multiple addons behave identically, treat the behavior as ecosystem behavior rather than an OUS bug.
7. Prefer ecosystem standards (LibDataBroker, LibDBIcon, Ace libraries, etc.) over addon-specific integrations.
8. Only introduce addon-specific compatibility when no standards-based solution exists.
9. Add the smallest safe OUS-side patch.
10. Test with and without the third-party addon enabled.
11. Document the integration boundary and architectural decision.

### Lessons Learned

- Do not assume third-party behavior is a bug until configuration options have been verified.
- Avoid writing compatibility code for configurable behavior.
- Favor long-term maintainability over one-off integrations.

## Current Case Study: Broker Minimap Launchers

Investigation outcome:

- OUS migrated from a manually managed minimap button to LibDataBroker-1.1 + LibDBIcon-1.0.
- HidingBar, Bartender4, Altoholic, and other mature addons demonstrated that broker launcher visibility may be controlled by the managing addon.
- The correct solution was to adopt the broker standard rather than implement addon-specific workarounds.
- Compatibility investigations should first verify addon configuration before assuming a code defect.

## Success Criteria

A compatibility task is complete when:

- OUS behaves correctly without the third-party addon.
- OUS behaves correctly with the third-party addon.
- No unnecessary addon-specific code has been introduced.
- The solution follows WoW ecosystem standards whenever possible.
- Documentation reflects the architectural decision.
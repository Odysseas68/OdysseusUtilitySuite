---
name: ous-reference-workspace
description: Use the external Odysseus Utility Suite engineering Reference workspace safely. Trigger when Codex needs local Blizzard UI source, frozen Odysseus prototypes, third-party addon/library references, research sandboxes, or guidance for avoiding production dependencies on Reference files under D:\WoWDev.
---

# OUS Reference Workspace

Use this skill when a task needs local reference code, API verification, third-party comparison, frozen prototypes, or research files under the external engineering workspace.

## Workspace Contract

Repository-configured engineering root:

```text
D:\WoWDev
```

Repository-configured shared reference location:

```text
D:\WoWDev\Reference
```

This workspace is intentionally outside the World of Warcraft installation.

Rules:

- Confirm the current locations from repository guidance before path-sensitive work; these are OUS workspace settings, not universal machine paths.
- Treat `D:\WoWDev\Reference` as local-only research material.
- Treat references as read-only during normal addon development.
- Do not edit upstream references directly.
- Production addon Lua must never load, require, include, or depend on files under `D:\WoWDev\Reference`.
- Reference code may guide implementation, but production patches must be made only in actual addon files.
- Avoid hardcoded machine-specific paths in prompts or docs unless writing local setup instructions.
- If a reference path is missing, report it instead of inventing APIs or falling back to memory.
- If a specialized Blizzard Research skill is absent, continue with `$ous-wow-retail-api-check` and this workspace contract rather than guessing or copying the missing skill into OUS.
- Do not recreate addon-local `Reference` directories or NTFS junctions inside the WoW installation.
- Do not create junctions from the WoW installation to `D:\WoWDev`; Battle.net may recursively traverse junction targets during Update and Scan & Repair.

## Layout

Current workspace layout:

```text
D:\WoWDev
|
+-- Reference
|   +-- Blizzard
|   +-- ThirdParty
|   +-- Odysseus
|   +-- Research
|   L-- Scripts
|
+-- Python
L-- Tools
```

## Reference Routing

- For Blizzard API, FrameXML, event, widget, and generated API documentation checks, prefer the current `wow-ui-source` location documented by the repository, presently `D:\WoWDev\Reference\Blizzard\wow-ui-source`.
- For production work, verify that the selected mirror or checkout represents current Retail/Mainline/LIVE before relying on it. Record branch or build evidence when relevant, but do not hardcode a transient build number into reusable guidance.
- Keep PTR and LIVE source conclusions separate. PTR evidence may identify a risk or future change, but it does not establish current production behavior.
- For third-party library or addon research, prefer `D:\WoWDev\Reference\ThirdParty\<LibraryName>`.
- For Odysseus prototypes or frozen references, use `D:\WoWDev\Reference\Odysseus`.
- Put experiments and temporary prototypes under `D:\WoWDev\Reference\Research` only when the user explicitly asks for research artifacts.
- Use `D:\WoWDev\Reference\Scripts` only for maintaining the reference workspace, not production addon code.

## Safety Checklist

Before applying lessons from reference code:

1. Confirm the reference path exists.
2. Identify whether the source is LIVE, PTR, Blizzard, Odysseus, third-party, research, or script material.
3. Treat current Blizzard Retail/Mainline/LIVE sources as the strongest source reference for production API facts while keeping verified user runtime evidence distinct.
4. Treat frozen Odysseus and third-party references as behavior examples, not code to copy blindly.
5. Keep all production edits in the addon source tree, outside `D:\WoWDev\Reference`.
6. Verify no addon-local `Reference` junction is being used.
7. Report any uncertainty about API signatures, source freshness, or reference ownership.

---
name: ous-reference-workspace
description: Use the external Odysseus Utility Suite engineering Reference workspace safely. Trigger when Codex needs local Blizzard UI source, frozen Odysseus prototypes, third-party addon/library references, research sandboxes, or guidance for avoiding production dependencies on Reference files under D:\WoWDev.
---

# OUS Reference Workspace

Use this skill when a task needs local reference code, API verification, third-party comparison, frozen prototypes, or research files under the external engineering workspace.

## Workspace Contract

Canonical engineering root:

```text
D:\WoWDev
```

Canonical shared reference location:

```text
D:\WoWDev\Reference
```

This workspace is intentionally outside the World of Warcraft installation.

Rules:

- Treat `D:\WoWDev\Reference` as local-only research material.
- Treat references as read-only during normal addon development.
- Do not edit upstream references directly.
- Production addon Lua must never load, require, include, or depend on files under `D:\WoWDev\Reference`.
- Reference code may guide implementation, but production patches must be made only in actual addon files.
- Avoid hardcoded machine-specific paths in prompts or docs unless writing local setup instructions.
- If a reference path is missing, report it instead of inventing APIs or falling back to memory.
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

- For Blizzard API, FrameXML, event, widget, and generated API documentation checks, prefer `D:\WoWDev\Reference\Blizzard\wow-ui-source`.
- When using `wow-ui-source`, prefer Retail/Mainline/live sources and generated API docs where available.
- For third-party library or addon research, prefer `D:\WoWDev\Reference\ThirdParty\<LibraryName>`.
- For Odysseus prototypes or frozen references, use `D:\WoWDev\Reference\Odysseus`.
- Put experiments and temporary prototypes under `D:\WoWDev\Reference\Research` only when the user explicitly asks for research artifacts.
- Use `D:\WoWDev\Reference\Scripts` only for maintaining the reference workspace, not production addon code.

## Safety Checklist

Before applying lessons from reference code:

1. Confirm the reference path exists.
2. Identify whether the source is Blizzard, Odysseus, third-party, research, or script material.
3. Treat Blizzard Retail/Mainline/live sources as the strongest API reference.
4. Treat frozen Odysseus and third-party references as behavior examples, not code to copy blindly.
5. Keep all production edits in the addon source tree, outside `D:\WoWDev\Reference`.
6. Verify no addon-local `Reference` junction is being used.
7. Report any uncertainty about API signatures, source freshness, or reference ownership.

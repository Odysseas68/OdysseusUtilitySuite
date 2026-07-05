---
name: ous-reference-workspace
description: Use the Odysseus Utility Suite shared Reference engineering workspace safely. Trigger when Codex needs local Blizzard UI source, frozen Odysseus prototypes, third-party addon/library references, research sandboxes, or guidance for avoiding production dependencies on Reference files.
---

# OUS Reference Workspace

Use this skill when a task needs local reference code, API verification, third-party comparison, frozen prototypes, or research files through the addon-local `Reference` junction.

## Workspace Contract

`Reference\` is a local engineering workspace exposed inside OUS through a Windows junction:

```text
OdysseusUtilitySuite\Reference
```

It points to the shared Interface-level workspace used by multiple addon projects.

Rules:

- Treat `Reference\` as local-only and ignored by Git.
- Treat it as read-only during normal addon development.
- Do not edit upstream references directly.
- Production addon Lua must never load, require, include, or depend on files under `Reference\`.
- Reference code may guide implementation, but production patches must be made only in actual addon files.
- Avoid hardcoded machine-specific paths in prompts or docs unless writing local setup instructions.
- If a reference path is missing, report it instead of inventing APIs or falling back to memory.

## Layout

Current workspace layout:

```text
Reference\README.md
Reference\Blizzard\wow-ui-source
Reference\Odysseus\OdysseusBuffBarsTest
Reference\ThirdParty\ElkBuffBars
Reference\ThirdParty\LibEQOL
Reference\ThirdParty\LibSettingsDesigner
Reference\Research
Reference\Scripts
```

## Reference Routing

- For Blizzard API, FrameXML, event, widget, and generated API documentation checks, prefer `Reference\Blizzard\wow-ui-source`.
- When using `wow-ui-source`, prefer Retail/Mainline/live sources and generated API docs where available.
- For third-party library or addon research, prefer `Reference\ThirdParty\<LibraryName>`.
- For Odysseus prototypes or frozen references, use `Reference\Odysseus`.
- Put experiments and temporary prototypes under `Reference\Research` only when the user explicitly asks for research artifacts.
- Use `Reference\Scripts` only for maintaining the reference workspace, not production addon code.

## Safety Checklist

Before applying lessons from reference code:

1. Confirm the reference path exists.
2. Identify whether the source is Blizzard, Odysseus, third-party, research, or script material.
3. Treat Blizzard Retail/Mainline/live sources as the strongest API reference.
4. Treat frozen Odysseus and third-party references as behavior examples, not code to copy blindly.
5. Keep all production edits in the addon source tree, outside `Reference\`.
6. Report any uncertainty about API signatures, source freshness, or reference ownership.

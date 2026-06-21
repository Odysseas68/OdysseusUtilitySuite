---
name: ous-documentation-maintainer
description: Maintain Odysseus Utility Suite documentation without changing addon code. Use for README.md, Documentation/README_v2.md, Documentation/ARCHITECTURE.md, Documentation/TODO_v2.md, CHANGELOG.md, or AGENTS.md audits and updates. Treat CLAUDE.md as reference-only unless the user explicitly requests changes.
---

# OUS Documentation Maintainer

1. Read `AGENTS.md` and the documentation files relevant to the request.
2. Inspect implementation code when needed to verify documented behavior, but do not modify addon source.
3. Treat code as the behavioral source of truth and report code or documentation mismatches.
4. Do not modify `CLAUDE.md` unless the user explicitly requests it.
5. Modify `AGENTS.md` only when development rules, architecture conventions, workflows, or project standards change.
6. Do not invent completed features, APIs, architecture, or status.
7. Mark uncertain or inferred details clearly.
8. Keep phase and current-focus statements accurate: OUS2 is transitioning from Phase 3 General Dashboard into Phase 4 Module Pages and OUS2 control polish.
9. Update only the related documents required by the requested behavior.
10. For a newly created file, determine whether documentation changes are actually necessary before editing documentation.
11. Avoid cosmetic documentation churn and unrelated prose rewrites.
12. Treat the Utilities and Openables OUS2 pages as completed module pages. Record Openables custom scale-control replacement and management-frame layering review as pending polish, not missing page implementation.

Report files inspected, documentation changes, mismatches, and remaining uncertainties.

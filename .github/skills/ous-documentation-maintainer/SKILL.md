---
name: ous-documentation-maintainer
description: Maintain Odysseus Utility Suite project documentation without changing addon code. Use for README.md, README_v2.md, ARCHITECTURE.md, TODO.md, TODO_v2.md, CLAUDE.md, CHANGELOG.md, or AGENTS.md updates, audits, phase tracking, and code-to-documentation consistency checks.
---

# OUS Documentation Maintainer

1. Read `AGENTS.md` and the documentation files relevant to the request.
2. Inspect implementation code when needed to verify documented behavior, but do not modify addon source.
3. Treat code as the behavioral source of truth and report code or documentation mismatches.
4. Do not invent completed features, APIs, architecture, or status.
5. Mark uncertain or inferred details clearly.
6. Keep phase and current-focus statements accurate.
7. Update related documents consistently when the requested behavior spans them.
8. Avoid unrelated prose rewrites and preserve useful project-specific detail.

Report files inspected, documentation changes, mismatches, and remaining uncertainties.

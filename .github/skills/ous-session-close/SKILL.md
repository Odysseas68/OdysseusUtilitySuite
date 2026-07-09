---
name: ous-session-close
description: Standardize the end-of-session engineering workflow for Odysseus Utility Suite. Use when a logical OUS development session has finished and the work should be reviewed, validated, summarized, and prepared for a user-approved commit or push.
---

# OUS Session Close

## Purpose

Standardize the end-of-session engineering workflow for Odysseus Utility Suite.

Use this skill whenever a logical development session has finished.

Do not automatically commit or push changes.

Always ask the user first.

---

## Session Checklist

Review all modified files.

Summarize:

- completed work
- remaining work
- discovered issues
- uncertainties

Verify documentation synchronization.

If completed work makes project documentation inaccurate or stale, recommend updating documentation before preparing a commit.

If `CHANGELOG.md` was modified during the session, perform a CHANGELOG audit.

Verify each calendar date appears only once as a top-level heading.

Preferred format:

```md
## [YYYY-MM-DD]
```

Never create multiple top-level sections for the same date.

If duplicate dates exist:

- merge them into a single date section
- preserve every existing changelog entry
- do not lose any bullets
- organize content under appropriate subsections such as:
  - Added
  - Changed
  - Fixed
  - Documentation
  - Infrastructure
  - Notes
- maintain reverse chronological order

Verify Engineering Workspace state:

- no `Reference` directory exists inside the World of Warcraft installation
- no NTFS junction from the World of Warcraft installation points into `D:\WoWDev`
- documentation still reflects the external `D:\WoWDev` workspace architecture

Verify feature-specific planning documents are updated when applicable.

Examples:

- `OUS2_XPBAR_PARITY.md`
- `BUFFBARS_DESIGN.md`
- `PHASE6_BASELINE.md`

If a feature-specific planning document exists, verify before preparing any Git commit that:

- completed work has been marked complete
- newly discovered review items have been added
- remaining work reflects the current project state

Run project validation:

- `luacheck`
- `git diff --check`

When `CHANGELOG.md` changed:

- verify duplicate date headings do not exist
- run `git diff --check`

Review Git status.

Mention:

- modified files
- new files
- deleted files
- untracked files

Evaluate whether the completed work represents a project milestone.

Examples:

- Phase completion
- Feature parity completion
- New engineering document
- New reusable workflow
- New reusable framework

If a milestone has been reached, recommend reviewing `CHANGELOG.md` before committing.

Do not modify the changelog automatically.

Generate:

- concise commit message describing one logical engineering milestone
- optional longer commit description

If the current changes contain multiple unrelated features, recommend splitting them into separate commits before committing.

Suggest the next logical engineering task.

Include expected files for the next patch.

List only files expected to change during the next patch so accidental scope expansion is easier to detect.

Example:

- `Config2/OUS2Page_Delves.lua`
- `Documentation/OUS2_XPBAR_PARITY.md`

Finally ask:

Would you like me to:

- prepare a commit only
- prepare a commit and push to GitHub
- continue development

Never assume.

Always ask.

After any user-approved commit and/or push, run a final Repository Clean Check.

Verify:

- `git status`

Expected result:

- working tree clean
- branch up to date with `origin/<branch>`

Report the final repository state.

---

## Rules

Never commit automatically.

Never push automatically.

Keep commits small.

Prefer one logical commit per engineering session.

Preserve project documentation discipline.

Do not modify project code as part of this skill.

---

## Expected Output

The skill should produce a concise engineering wrap-up including:

- Summary
- Validation
- Git status
- CHANGELOG audit, if `CHANGELOG.md` was updated
- Suggested commit message
- Suggested next task
- Expected files for the next task
- Commit/push question
- Session Statistics

If `CHANGELOG.md` was updated, include:

- CHANGELOG audit performed
- duplicate dates found or not found
- dates merged, if applicable

Session Statistics should include:

- Files modified
- Documentation files modified
- Lua files modified
- Skills modified
- New files created
- Git commits prepared
- Git commits created
- Git pushes performed

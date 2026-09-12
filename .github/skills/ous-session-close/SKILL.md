---
name: ous-session-close
description: Review, validate, summarize, and optionally publish a completed Odysseus Utility Suite change. Use when an OUS task reaches a review, runtime-validation, commit, or push checkpoint.
---

# OUS Session Close

Close an OUS task proportionally to its scope. Do not alter implementation merely to complete this workflow.

## Review and validation

1. Check the worktree once and identify modified, added, deleted, and untracked files. Preserve unrelated pre-existing changes.
2. Review the focused diff once. If the work contains unrelated changes, recommend or prepare separate commits as authorized.
3. Run only relevant validation:
   - LuaCheck changed Lua files, not the whole addon by default.
   - Run focused scripts or static checks when the changed artifact has them.
   - Run `git diff --check` once before staging.
   - Do not run LuaCheck for documentation-only or skill-only changes.
4. For runtime-sensitive UI, combat, secure-action, event, or gameplay behavior, report the focused in-game test plan and wait for user runtime evidence before publication when practical.
5. Do not repeatedly rerun status, diff, stat, HEAD/origin, ahead/behind, or warning-baseline checks unless a failure or scope discrepancy requires it.

## Conditional documentation checks

- Update or recommend documentation only when the completed behavior makes an existing claim stale.
- If `CHANGELOG.md` changed, verify the edited section and ensure each calendar date has only one top-level `## [YYYY-MM-DD]` heading. Merge duplicate same-date sections without losing entries.
- Inspect feature planning documents only when the task changes their tracked status.
- Check the external Reference-workspace or junction contract only when the task touches those paths, dependencies, or instructions.

## Commit and push authority

- Never infer permission to commit or push from task completion.
- If the current user request explicitly authorizes a commit or push, proceed within that scope without asking again.
- If authorization is absent, stop after the review report and ask once whether the user wants a commit, a commit and push, or further work.
- Stage only explicitly reviewed paths. Verify staged names and ensure no unintended unstaged changes were introduced before committing.
- Keep one logical change per commit unless the user requests otherwise.
- Push only when explicitly authorized. Do not create tags, releases, branches, or pull requests unless separately requested.

After an authorized push, verify once that `HEAD` matches `origin/<branch>`, ahead/behind is `0/0`, and the worktree is clean. Report any environmental warnings separately from content failures.

## Expected output

Report only what the checkpoint needs:

- completed change and files;
- validation and runtime evidence;
- risks or remaining uncertainty;
- commit subject and hash when committed;
- push and clean-state proof when pushed;
- the next logical task only when useful.

---
name: ous-release-manager
description: Prepare, validate, package and publish Odysseus Utility Suite releases through separately authorized checkpoints. Use for OUS release scope, metadata, staging, archive, release-commit, tag or GitHub Release tasks.
---

# OUS Release Manager

Perform only the release phase the user requests. This skill is guidance, not permission to run later phases. Honor read-only limits and existing authorization without asking again for an already-authorized action. Do not change working production behavior to satisfy a release checklist.

## 1. Scope and evidence

- Read `AGENTS.md`, the requested release scope and relevant current changes once. Consult `.github/skills/ous-session-close/SKILL.md` for proportional validation and `.github/skills/ous-documentation-maintainer/SKILL.md` for documentation conventions.
- Confirm the requested version, build date, expected branch/commit and intended deliverable before dependent actions. Do not invent dates, versions or test results. Respect the feature freeze and preserve unrelated work.
- Compare changes with the last released source and later implementation records. Separate new functionality, fixes, dependency maintenance, historical acceptance, unverified boundaries and deferred work. Do not reopen completed migration or approved visuals without evidence.

## 2. Optional database maintenance

`FlightData.lua`, `Odysseus_RoutingDB.lua` and `OpenablesDB.lua` are production databases. FlightData has an existing user-controlled script workflow: never discover and run update scripts automatically. Update a database only when explicitly requested; preserve its schema, existing compatibility and behavior. Validate the affected Lua and relevant functionality before including an authorized update in the release.

## 3. Five coordinated metadata actions

1. Update Version in `OdysseusUtilitySuite.toc` to the approved release version.
2. Verify the OUS2 General version display.
3. Verify the OUS2 General build-date display against TOC X-Build-Date.
4. Update `Config2/OUS2Page_Changelog.lua` with concise player-facing notes.
5. Update `CHANGELOG.md` with the same release substance.

General currently reads Version and X-Build-Date using `C_AddOns.GetAddOnMetadata`; it formats dotted build dates with hyphens. Leave `Config2/OUS2Page_General.lua` unchanged when that dynamic path is correct. Preserve Interface declarations, load order, SavedVariables and defaults unless separately authorized.

Use version/date release headings and the category conventions in AGENTS. Preserve every historical changelog entry. Keep in-game text plain-font compatible. Verify notes against source changes and bounded acceptance; do not describe dependency maintenance as a gameplay fix without evidence. Do not include probes or release tooling as in-game features.

## 4. Production staging

Inspect `Tools/package_release.py` and `Tools/production_assets.txt` before relying on their current contract. When staging is authorized, run from the repository root:

```powershell
python -B Tools/package_release.py --dry-run
python -B Tools/package_release.py
```

Run the second command only after the dry-run passes. It replaces its fixed staging outputs; do not rerun it during archive-only or read-only tasks. Its current outputs are:

- `release/staging/OdysseusUtilitySuite/` — player-facing addon tree.
- `release/staging/manifest.json` — completion manifest outside the addon tree, containing relative paths, file count, byte sizes and SHA-256 hashes.

Use the TOC's direct Lua/XML entries and transitive XML Script/Include dependencies, including embedded libraries. Assets come from the explicit approved TGA list. Verify required source paths, capitalization and dependency existence; reject escaping paths and external symlink/reparse traversal.

Compare actual staged membership, sizes and hashes with the manifest and production sources. Check for stale or unexpected files. Derive counts from the approved current inputs; no historical count is a permanent requirement. Investigate differences instead of changing the allowlist merely to hit a number. New runtime assets require explicit review of their references and allowlist inclusion.

## 5. Git and distribution boundaries

Never distribute `Documentation/` (including `Documentation/Research/`), `Scripts/`, `Tools/`, `AGENTS.md`, repository skills, local editor/settings directories, source mockups, research exports, SavedVariables backups, temporary extractions, generated archive inputs or release/build output. Keep README, repository CHANGELOG, development configuration and the staging manifest outside the addon root.

`Documentation/Research/` is intentionally local-only and Git-ignored: preserve its contents, never add them to Git, and avoid GitHub-bound links that require those local files. Scripts, local settings, temporary extractions and generated archives must not be newly added. Maintained documentation, repository guidance/skills, relevant project configuration, production source/assets and release tooling may belong in the explicitly reviewed Git changeset while remaining excluded from distribution.

Git ignore rules do not define archive contents. The packager's allowlist does. Do not copy the repository wholesale, import external WoW.export assets or add a research addon to the production package.

## 6. Runtime acceptance

Require explicit, bounded user-reported WoW acceptance for relevant production changes before approving the package for release. Preserve already reported acceptance and identify the remaining untested cases rather than assuming exhaustive safety.

Prioritize affected module behavior, SavedVariables compatibility, OUS2 navigation/combat and preview cleanup, artwork, Retail API compatibility and frame layering/strata when changed. Offline checks do not establish native secrets, taint or geometry behavior. Metadata-only changes warrant a metadata/changelog smoke check, not automatic reruns of large historical suites. Report blockers separately from monitored edges and optional polish.

## 7. Archive checkpoint

Create a ZIP only when archive generation is authorized and staged-manifest validation plus relevant runtime acceptance are approved. Use the existing validated staging inputs; do not silently rebuild them. Recheck manifest membership, sizes, hashes and release TOC metadata before creating output.

- Place the final ZIP under `release/` with a versioned filename; never overwrite a validated archive silently. Identify any existing artifact and stop if replacement authority or identity is uncertain.
- Include only manifest-listed files under one `OdysseusUtilitySuite/` root, preserving relative case and forward slashes. Reject duplicates, unsafe components and external links. Do not include `release/`, `staging/` or `manifest.json` inside the addon.
- Prefer sorted entries, fixed release-derived timestamps and consistent metadata. Build a temporary archive inside `release/`; promote it only after validation.
- Reopen the ZIP, test integrity, compare exact member names and uncompressed sizes/SHA-256 values with the manifest, verify metadata and exclusions, then calculate the final ZIP SHA-256. Archive creation alone is not proof of validity.

## 8. Exact Git changeset

Before authorized staging, inventory tracked modifications/deletions and non-ignored untracked files once. Review focused diffs, isolate unrelated work and propose the exact path/status list. Explicitly include new runtime assets and tooling. Honor authorized deletions; do not restore retired guidance or assume every dirty file belongs in the release.

Run `git diff --check`. Stage only the agreed paths, never `git add -A` or `git add .`. Require a known index baseline; stop on unexpected pre-staged content. Inspect staged names/statuses and content, run `git diff --cached --check`, and verify indexed metadata, changelogs, dependencies and assets. Stop if the index differs from the agreed scope. Read-only review does not authorize staging.

## 9. Commit and push checkpoints

Staging/committing requires explicit authorization; pushing requires separate explicit authorization. Do not infer either from successful tests or skill invocation. Create only the requested commit(s), verify their exact paths and report remaining work without cleaning unrelated changes.

Before an authorized push, verify the expected branch, HEAD, origin fetch/push URLs and reviewed worktree/index state. Fetch the intended branch once without fetching tags unnecessarily; confirm the expected fast-forward relationship and exact outgoing commits. Stop on mismatch; never merge, rebase, reset, amend or force-push to make release checks pass. Push only the authorized branch with automatic tag following disabled. Verify the remote commit, local tracking ref, ahead/behind and worktree state once afterwards.

## 10. Annotated tag and publication checkpoints

Creating/pushing a tag, creating/publishing a GitHub Release and uploading its ZIP each require explicit authorization. One request may authorize several named operations; do not infer later permissions from an earlier checkpoint.

- Tag: verify expected commit, branch and remote; check both local and remote tag absence. Create the requested annotated tag, verify its peeled commit, push only that tag and verify the remote object/target. Stop on existing tags or mismatches; do not overwrite tags or push branches incidentally.
- Publication: verify the existing annotated tag's remote target, approved notes and exact ZIP hash/content. Check for existing releases **and authenticated drafts/assets** before creating anything. Never create a duplicate or overwrite an unexpected release/asset.
- Prefer a draft to upload/verify the asset before publishing when the authorized scope permits. Retain the created release ID: GitHub's release-by-tag endpoint may return 404 for drafts, so use the authenticated release list or ID to find that same draft rather than creating another.
- Publish with the requested stable/draft/prerelease status, using the approved repository changelog entry. Verify title, tag/peeled commit, body, asset name/size and public download availability as applicable. Download the uploaded archive and verify its SHA-256; command success or upload success alone is insufficient.
- Report the exact resulting draft/published/asset state on failure. Do not retry by recreating a release or clobbering assets. Stop after the authorized publication verification; no extra tags, branches or uploads.

## 11. Completion report

Report the requested version/build date, relevant runtime acceptance and limits, commit/tag if created, manifest/package counts, ZIP filename/size/SHA-256, publication URL if published, preservation checks and remaining unauthorized/unperformed steps. Distinguish planned, offline-validated, runtime-accepted, committed, pushed, tagged and published states.

## 12. Failure handling and efficiency

On a failed gate, stop before the next destructive or externally visible action, explain the discrepancy and preserve source/research/artifacts. Do not silently repair scope, overwrite output, rewrite history or publish partial success. Obtain authorization for scope-changing corrections.

Use one focused inventory, relevant read pass, necessary edit pass, targeted validation and final readback/diff review. Repeat identity checks only at the relevant mutation boundary or when state may have changed. Reuse the current packager and approved artifacts; do not add build frameworks, network downloads or release automation merely to follow this skill. This skill does not itself execute or authorize a release.

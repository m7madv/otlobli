# AGENTS.md

Mandatory rules for any AI working on this project.

## First Steps Before Any Edit

1. Read `CURRENT_STATE.md`.
2. Read `AI-HANDOFF.md`.
3. Read `docs/KNOWN_ISSUES_AND_DECISIONS.md`.
4. Read this file.
5. Run:

```bash
git status --short
git rev-parse --abbrev-ref HEAD
git log -5 --oneline
```

If files are already modified, assume they belong to the user or another AI. Do not revert or overwrite them.

## Source Of Truth

- Usual active branch: `codex/customer-wallet-group-orders`
- Do not assume `main` is latest.
- Prefer current code plus `CURRENT_STATE.md`, `AI-HANDOFF.md`, and
  `docs/KNOWN_ISSUES_AND_DECISIONS.md`.
- Older docs such as `PROJECT-CONTEXT.md` or `CHAT_SUMMARY.md` are not first-read sources.

## Forbidden

- Do not replace project files with copies from an older branch.
- Do not restore Admin or Customer UI from an old branch without deliberate comparison.
- Do not run `git reset --hard` or `git checkout --` for changes the user did not explicitly ask to discard.
- Do not commit/push staged changes that are not yours unless the user explicitly asks.
- Do not change payment, wallet, or completed-order logic during a limited fix unless the user clearly asks.

## Critical SHEIN iPhone Freeze Invariant

Before changing SHEIN, `@capgo/capacitor-inappbrowser`, native WebView code, store-region polling, injected scripts, or app foreground/background lifecycle:

1. Read `docs/SHEIN_IOS_FREEZE_GUARD.md`.
2. Preserve the iPhone 16/iOS 27 detach/reattach fix: `WKWebViewController.otlobliForceRecompose()`, its `appDidBecomeActive` call, scroll/constraint restoration, and the Android `otlobliOnHostResume()` defense.
3. Preserve the `JSON.stringify` active-store comparison in the `[storeRegions]` effect; never rebuild SHEIN on unchanged settings.
4. Run `npm run verify:shein-freeze-guard` after dependency installation/patching and before handoff. `npm run build` runs it automatically.
5. Any affected release requires five real iPhone 16 background/resume cycles plus a separate force-quit/cold-launch test. Do not claim device acceptance from build/simulator checks.

Never add, remove, or retime native recompose bursts without deliberate comparison and real iPhone 16 acceptance. The current verified patch uses `appDidBecomeActive` with a `0.25s` delay; do not document nonexistent guards as if they were implemented.

## Low-End Device Performance Invariant

Performance on weak phones is a release requirement; features must not be removed to make budgets pass.

1. Read `docs/LOW_END_DEVICE_PERFORMANCE_GUARD.md` before runtime, UI, WebView, polling, injected-script, dependency, or bundle changes.
2. Apply the installed `vercel-react-best-practices` skill for React performance work.
3. Keep startup work, persistent timers, DOM scans, fixed-layer effects, memory, and network payloads bounded. Pause/defer non-critical work when hidden and load heavy features only when needed.
4. `npm run build` must pass `verify:performance-budget`; never raise a budget merely to accept regression.
5. Any affected release must retain all features and be tested on narrow viewports plus a real weak/old Android device when available. Record unperformed device acceptance honestly.

## Mandatory Immediate Project Sync

Every completed modification batch must be propagated and documented in the same task before handoff. This applies to code, UI, configuration, migrations, native settings, workflows, deployments, and release artifacts; it is not limited to large or "important" changes.

1. Update `CURRENT_STATE.md` with the current factual state.
2. Update `AI-HANDOFF.md` with what the next AI must know.
3. Update `SESSION_SUMMARY.md` with a concise user-facing summary.
4. If customer web code or shared configuration changed, run the web build and synchronize every affected native project (`android` and `ios`) before building artifacts. If a platform cannot be synchronized locally, propagate the exact source through its isolated build branch/workflow and record the limitation.
5. If database or backend behavior changed, keep the migration, `supabase/schema.sql`, and affected edge/server code consistent. Record exactly what was deployed and what remains local.
6. If Admin code changed, build it and keep its documented production/local status explicit. Do not claim deployment unless it actually succeeded.
7. Record version numbers, artifact paths, hashes, validation performed, and any unverified device acceptance honestly.

Do not defer this synchronization to a later chat and do not rely on git history as a substitute. Documentation-only edits do not require native rebuilds, but the three state files must still be updated once. Keep the files short by updating the newest state instead of duplicating long history.

## Design

When the user asks for interface design or design changes:

- If the user provides an approved Figma file, link, or existing design, treat it as the source of truth and implement it faithfully.
- When no approved design exists, design directly in production code with the installed `frontend-design` skill, then review accessibility and UX with `web-design-guidelines` and React performance with `react-best-practices`.
- Figma is an optional collaboration and design source, not a blocker. Use it when the user requests it or when an existing Figma source must be preserved.
- Keep the result distinctive to Otlobli, compact, Arabic-first, responsive, accessible, and visually verified at relevant mobile and desktop sizes.
- Avoid generic dashboard templates, oversized authentication cards, decorative clutter, and unverified visual claims.

## Token Discipline

- Read the short handoff files first.
- Use `rg`/targeted searches instead of opening large files blindly.
- Avoid old summaries unless the task specifically needs history.
- Keep status updates concise and practical.

# AGENTS.md

Mandatory rules for any AI working on this project.

## First Steps Before Any Edit

1. Read `CURRENT_STATE.md`.
2. Read `AI-HANDOFF.md`.
3. Read this file.
4. Run:

```bash
git status --short
git rev-parse --abbrev-ref HEAD
git log -5 --oneline
```

If files are already modified, assume they belong to the user or another AI. Do not revert or overwrite them.

## Source Of Truth

- Usual active branch: `codex/customer-wallet-group-orders`
- Do not assume `main` is latest.
- Prefer current code plus `CURRENT_STATE.md` and `AI-HANDOFF.md`.
- Older docs such as `PROJECT-CONTEXT.md` or `CHAT_SUMMARY.md` are not first-read sources.

## Forbidden

- Do not replace project files with copies from an older branch.
- Do not restore Admin or Customer UI from an old branch without deliberate comparison.
- Do not run `git reset --hard` or `git checkout --` for changes the user did not explicitly ask to discard.
- Do not commit/push staged changes that are not yours unless the user explicitly asks.
- Do not change payment, wallet, or completed-order logic during a limited fix unless the user clearly asks.

## Documentation Discipline

After a stable important change, update:

1. `CURRENT_STATE.md`
2. `AI-HANDOFF.md`
3. `SESSION_SUMMARY.md`

Keep these files short. Long history belongs in git history, not in first-read context.

## Figma And Design

Designs must come from Figma only.

When the user asks for interface design or design changes:

- Treat Figma as the only design source.
- If Figma tools/permissions are available, use the relevant Figma skills.
- If Figma is unavailable or needs reauthentication, explain the minimum reconnect step and continue only with review or code implementation that does not invent a new design.

## Token Discipline

- Read the short handoff files first.
- Use `rg`/targeted searches instead of opening large files blindly.
- Avoid old summaries unless the task specifically needs history.
- Keep status updates concise and practical.

# Otlobli quick handoff

Read this only as an entry point; it deliberately does not duplicate release
history.

## First read

1. `CURRENT_STATE.md` — live candidate, artifacts, and honest acceptance state.
2. `AI-HANDOFF.md` — implementation detail for the next change.
3. `docs/KNOWN_ISSUES_AND_DECISIONS.md` — permanent problem log and rejected
   fixes; do not delete it.
4. `docs/PROJECT_MAP.md` and `AGENTS.md` — ownership and mandatory workflow.

## Current priorities

- SHEIN iPhone behavior is the highest-risk path. Read both
  `docs/SHEIN_IOS_FREEZE_GUARD.md` and
  `docs/LOW_END_DEVICE_PERFORMANCE_GUARD.md` before touching it.
- Preserve the guarded native recompose, store-region equality guard, and
  narrow product-only chunk recovery. A normal resume must not close/reopen a
  healthy SHEIN WebView or produce a visible flash.
- `server/` is the active WhatsApp server. `server-whatsapp/` is historical.
- `supabase/schema.sql` is not proof of production schema; query the linked
  project before database changes.

## Completion standard

For every modification batch: update the three state documents, run the
relevant build/guards, synchronize affected native shells, preserve unrelated
local work, and report unperformed physical-device testing honestly.

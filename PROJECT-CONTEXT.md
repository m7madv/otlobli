# PROJECT-CONTEXT.md

Deprecated as a source of truth.

This file previously held long session context and some old state.
It should not be used as the first reference anymore.

Use these files instead:

1. `AGENTS.md`
2. `CURRENT_STATE.md`
3. `AI-HANDOFF.md`
4. `SESSION_SUMMARY.md`

Active branch:

- `codex/customer-wallet-group-orders`

Current reliable references:

- customer app: `src/App.tsx`
- admin app: `admin/src/AdminApp.tsx`
- admin styles: `admin/src/styles.css`
- schema: `supabase/schema.sql`

Reason for deprecation:

- older context here can conflict with newer branch reality
- some older copies had encoding issues
- the project previously had two parallel development lines, which caused old admin state to reappear when the wrong context was used

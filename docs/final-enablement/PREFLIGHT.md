# v86.208 final-enablement preflight

Verified on 2026-08-21 before application-behavior changes.

## Protected source

- Source branch: `codex/otlobli-final-production-release`.
- Source worktree: `C:\Users\MOHAMMAD\Projects\otlobli-final-production-release`.
- Verified source HEAD: `c18363c9a5712239d53bdf97880058036f9b2198`.
- Production code commit retained in that history: `6ae98b59b0aefac9471215a25cfd8f6f0888e843`.
- Source version/build: `86.207/1069`.
- Source worktree was clean and tracked `origin/codex/otlobli-final-production-release`.
- No reset, rebase, merge, deletion, or edit was performed in the source worktree.

## Isolated release line

- Branch: `codex/otlobli-v86-208-final-enablement`.
- Worktree: `C:\Users\MOHAMMAD\Projects\otlobli-v86-208-final-enablement`.
- Initial HEAD: `c18363c9a5712239d53bdf97880058036f9b2198`.
- Worktree was clean at creation.
- `86.208` and build `1070` were absent from local branches/tags/history, the fetched origin branch namespace, GitHub releases, and the latest 100 GitHub Actions runs before reservation.
- Reserved version/build: `86.208/1070`.
- Bundle/application ID remains `com.otlobli.app`.

## Build discipline

- No candidate artifact was generated during preflight.
- Maximum remains one signed/internal release candidate, plus one final build only if that candidate exposes a concrete defect.
- Portal submission is excluded unless separately authorized by the owner.

## Behavior boundaries

- Product capture is frozen under `PRODUCT_CAPTURE_PROTECTION.md`.
- Temu behavior is frozen unless a concrete regression is found.
- Existing product Back, root Back, store chooser, double-tap Home store switch, browser ownership, website data, cookies, cache, verification session, and capture bridge behavior are protected.
- Policy/region/performance changes must stay around those boundaries and may not introduce reload recovery, WebView recreation, a second browser, synthetic input, or lifecycle experiments.


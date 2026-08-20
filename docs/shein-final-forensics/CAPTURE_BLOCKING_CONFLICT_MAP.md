# Capture/Blocking static conflict map

Baseline audited: `846de3798e5decc4e46fb9e7ca40e90c74e201f7` (`86.205/1067`).

This is a static audit, not physical proof. Line numbers refer to the baseline
`ios/App/App/SheinCleanBrowser/SheinCleanBrowserScripts.swift` before forensic
instrumentation.

## Capture module

| Concern | Exact location | Behavior |
| --- | --- | --- |
| Installation guard/global | lines 249-253, 307-311 | Main frame only; returns when `window.__otlobliCleanCapture` already exists, then publishes the frozen `window.__otlobliCleanCapture` API. |
| Module state | lines 253-255 | One generated `documentId`; no shared mutable state with Blocking. |
| DOM reads | lines 257-259, 265-275, 284-305 | Reads exact metadata, `h1`, price candidates, and selected size/color radios with `querySelector`. |
| DOM writes | none | Capture does not create, hide, remove, replace, style, or attribute-mark any element. |
| CSS/style injection | none | No stylesheet and no inline-style change. |
| Event listeners/cancellation | none | Capture installs no listener and never calls `preventDefault`, `stopPropagation`, or `stopImmediatePropagation`. |
| MutationObservers/timers | none | Capture has no observer, polling, timeout, interval, rAF, or microtask loop. |
| History/navigation | lines 276-282 | Reads the sanitized current origin/path and product ID only; it does not navigate or write history. |
| Product-root assumptions | lines 276-305 | Product page is inferred from `-p-<digits>` or `product:retailer_item_id`; price/title/variant reads are bounded. |
| Native/React messages | none at install time | Native invokes `snapshot()` through an explicit Add button; the native controller emits the resulting sanitized product payload. |
| Cleanup | none required | The API belongs to its document and Capture owns no observer/listener/timer. |

## Blocking module

| Concern | Exact location | Behavior |
| --- | --- | --- |
| Installation guard/global | lines 319-323, 390-392 | Main frame only; returns when `window.__otlobliCleanBlocking` exists and publishes a frozen API with `dispose`. |
| Module state | lines 323-334 | Exact purchase-control selector, module-local `WeakSet`, one observer, and one stopped flag. |
| DOM selectors | lines 323-331 | Only explicit Add-to-Bag/Add-to-Cart aria labels and `data-testid="product-detail-add-to-bag"`. |
| DOM attributes/styles | lines 351-356 | Adds only `data-otlobli-clean-blocked="native-purchase-control"` and inline `display:none!important` to a matched purchase control. |
| Elements hidden/removed/replaced | lines 351-356 | Hides matched controls; removes/replaces no nodes. |
| CSS/style injection | none | No stylesheet or broad selector is injected. |
| Event listeners/cancellation | line 389 | One passive, once-only `pagehide` cleanup listener; no input listener and no cancellation. |
| MutationObserver | lines 368-381 | Watches only added child nodes (`childList`, `subtree`) and scans at most 48 added nodes per callback. |
| Timers | none | No timer, polling, rAF, promise loop, or MessageChannel. |
| History/navigation | none | No URL, location, history, or navigation writes. |
| Native messages | lines 336-348 | Sends bounded count/category/path metadata through `otlobliCleanBlocking`; no page content or credentials. |
| Cleanup | lines 383-390 | Sets stopped, disconnects the observer, and clears the reference on `pagehide`. |

## Overlap analysis

| Potential conflict | Static result |
| --- | --- |
| Shared global name or installation guard | No overlap: `__otlobliCleanCapture` and `__otlobliCleanBlocking` are distinct. |
| Shared DOM nodes | No proven overlap. Capture reads metadata, `h1`, price, and selected variant radios; Blocking mutates only explicit purchase controls. |
| Blocking removes a Capture dependency | No: Blocking removes no nodes, and its selectors do not include Capture's read targets. |
| Blocking matches Otlobli Capture UI | No: Capture creates no in-page UI. The Add control is native navigation chrome outside the page DOM. |
| Observer feedback loop | Not supported statically. Blocking observes child-list additions only; its own attribute and style changes are not in the observer options. The `WeakSet` also prevents reprocessing the same element. |
| Duplicate installation | Both modules have per-document guards. Physical logs must still prove one install per document. |
| Event/input conflict | No module installs an input listener or cancels an event. |
| Timer/scheduler conflict | No: neither module owns recurring timers; Capture owns no scheduler at all. |
| Navigation readiness race | Possible only as timing, not as a statically identified conflict: Blocking scans at document start/DOMContentLoaded and added-node delivery, while Capture remains dormant until the native Add command. Physical operation timestamps/root fingerprints are required. |

## Static verdict and required instrumentation

The source does not reveal a direct Capture/Blocking conflict. In particular,
the combined mode cannot be blamed on an observer self-loop, broad input
interception, shared global, or a Blocking selector deleting a Capture target
from this static evidence.

The forensic build must record only Otlobli-owned operations:

- module install/duplicate-guard result and `documentId`;
- Blocking scan trigger, selector category, match/change counts, duration, and
  root fingerprint before/after;
- Capture snapshot start/end, duration, product-root result, and root
  fingerprint before/after;
- JavaScript error/rejection observed immediately after an owned operation;
- the existing trusted-click reaction and event-loop/root evidence.

If a fresh combined container fails while its required Script bodies are
healthy, these records define the first module boundary. If it fails earlier
with the bodyless-304/ChunkLoadError sequence, this map does not authorize a
module change.


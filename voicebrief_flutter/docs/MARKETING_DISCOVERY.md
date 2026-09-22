# VoiceBrief organic discovery

## Latest Google inspection — 2026-09-22

- Direct owner-session inspection confirms English `https://voicebrief-legal.vercel.app/` **INDEXED**: “URL is on Google” and “Page is indexed”. No new request was sent for it. Inspection reference: `https://search.google.com/u/1/search-console/inspect?resource_id=https%3A%2F%2Fvoicebrief-legal.vercel.app%2F&id=QoLOSw7xzkhSsGsRD82Oow`.
- Arabic `https://voicebrief-legal.vercel.app/ar` is **Crawled - currently not indexed**, superseding20Sep's unknown-URL snapshot. Google reports the sitemap and English homepage as discovery sources; crawl allowed and page fetch successful; last crawl displayed20Sep2026 13:45:31 (Google UI time). Indexing-allowed/canonical fields are unavailable, not evidence of a new blocking directive. Inspection reference uses the same property and `id=wlrg11G8bI5Q8ThIJ-3KHA`.
- Exactly ONE manual Arabic indexing request was made this run after the previous wait elapsed. Google returned **Quota exceeded**, retry tomorrow. Recorded by `2026-09-22T08:14:36Z`; no further manual request before `2026-09-23T08:14:36Z` (11:14:36 Riyadh). A23Sep09:00on-time run must be read-only. No accepted manual request exists for either URL; two refusals documented overall (English20Sep, Arabic22Sep). No repeat, account switch, limit bypass, or human-check solving.
- Sitemap still shows success,10discovered pages, latest read21Sep; no resubmission. This is not evidence all10pages are indexed. Heartbeat `voicebrief` remains ACTIVE and unchanged because Arabic is pending; stop only once both target URLs are confirmed indexed. No guaranteed ranking, traffic or AI inclusion.
- This batch only records browser findings in the four state/discovery documents. Production deployment, website hash, app/backend/store/emulator state unchanged; no new build/deployment or physical-device checks apply. These results supersede the historical20Sep inspection below.

## Scope and truth

The owner requested free, professional promotion of the published iPhone app on 2026-09-19, then explicitly requested further publication/discovery improvements WITHOUT changing the app on 2026-09-20. No advertising spend, paid directory placement, fabricated reviews, upvotes, downloads, or bulk unsolicited messages are authorized by this implementation. Never promise placement in search results or AI answers.

The public US App Store listing was fetched live on 2026-09-19: `VoiceBrief: Audio Summaries`, app ID `6805194629`, publisher `mohammad alzouabi`, version `0.1.2`, iPhone/iPad, iOS 14+, 11 interface languages, free download with in-app purchases. Do not conflate similarly named products or promote Google Play as publicly released without checking.

The former root of `https://voicebrief-legal.vercel.app/` redirected to privacy. The marketing build removed only that root redirect and now provides ten static pages:

- `/` and `/ar`: product, actual app screenshots, App Store download, limitations, FAQs.
- `/guides/whatsapp-voice-notes` and `/ar/guides/whatsapp-voice-notes`: practical sharing instructions without promising unsupported direct app launch.
- `/guides/arabic-audio-to-text` and `/ar/guides/arabic-audio-to-text`: choosing transcripts vs summaries, reviewing dialects/names/numbers, and cloud privacy.
- `/guides/voice-notes-to-calendar` and `/ar/guides/voice-notes-to-calendar`: separating appointments, clarifying missing times, verifying saved events, calendar vs app-owned alarms. Examples explain review, not guaranteed extraction accuracy.
- `/press` and `/ar/press`: publisher, app ID, factual directory copy, icon, and screenshots.

Existing privacy, terms, support and deletion content/forms/submit handlers remain unchanged. On20Sep, only their brand anchors and a small locale-aware `app.js` navigation block changed: the brand now points to the product homepage, with an accessible localized name. A search sample returned existing legal-page URLs, making this a concrete discovery path; that sample is not a complete indexing report. No native code, subscriptions, backend processing, prices, or App Store metadata changed.

## Design and implementation

Preserve the existing Obsidian Monochrome + Signal Blue identity. Tokens: white `#fff`, ink `#090909`, secondary `#636366`, surface `#f5f5f7`, border `#d1d1d6`, accessible link blue `#0066cc`. Platform sans fonts for body/display, restrained monospace for the actual three-step sequence. Product imagery is the signature, not invented testimonials or AI-generated interfaces.

The UI/UX skill search suggested product demo + features/minimalism. We adopted that structure, not its unrelated red palette or external Inter font. Existing brand decisions take precedence. Semantic HTML works without JavaScript, Arabic uses RTL and separate canonical URLs, images have fixed dimensions and below-fold lazy loading. No analytics, cookies, extra runtime dependencies, third-party requests, background polling, or animation.

The20Sep targeted UI/UX search emphasized accessible navigation names and keyboard focus. Existing typography/layout were reused for guides; ordinary crawlable links, visible breadcrumbs, a homepage guides section, related guides and footer links connect all pages. `Article` and `BreadcrumbList` structured data reflect visible editorial content and authorship; there is no promise of search rich results. The app facts retain their actual19Sep verification date rather than claiming a fresh store check.

Eight screenshots are copied byte-for-byte from `store_assets/localized/{en,ar}/iphone`, generated from production Flutter widgets with synthetic sample content. They are not physical-device captures. No image generation was needed.

`scripts/build_marketing_site.mjs` and editorial `scripts/marketing_guides.mjs` generate HTML, sitemap/hreflang, robots, machine-readable public facts, and hashes the JSON-LD scripts for the existing strict CSP. They copy only selected public assets. The IndexNow ownership file is public by design and is created once, not rotated on each build. No special AI file, prompt injection, invented rating schema, or claim of guaranteed AI citation.

Build/check:

```text
node voicebrief_flutter/scripts/build_marketing_site.mjs
node --test voicebrief_flutter/scripts/marketing_site_test.mjs
node voicebrief_flutter/scripts/preview_marketing_site.mjs
```

The preview is loopback-only on port 4179 and accepts GET/HEAD only. Marketing output is plain static HTML/CSS, not the unrelated Otlobli customer web bundle; mobile synchronization/builds are not applicable.

Browser QA: with the preview running, use a dedicated headless `playwright-cli` session and `run-code --filename voicebrief_flutter/scripts/marketing_browser_qa.js`. This is a CLI function, not a Playwright Test suite. It checks40layouts,8legal navigation cases,language switching and keyboard interaction without submitting forms. Close only the task-owned browser and preview afterward.

## Free distribution channels checked

1. **Product Hunt:** free submission through the owner's personal account. `/posts/new` currently returns a sign-in page. Use the kit below, acknowledge the maker relationship, and ask for genuine feedback, never upvotes. Not submitted until a confirmation exists.
2. **AlternativeTo:** requires an account; free submissions are moderated and can wait without a promised review time. English UI is supported, so VoiceBrief meets that language prerequisite. A similarly named listing must not be claimed as ours. Not submitted until a confirmation exists.
3. **SaaSHub:** its current submission rules reject products using free subdomains, including Vercel-style ones. Do not submit this free-hosted website there or buy a domain without owner approval.
4. **AppAgg:** its official `/add/?hl=en` page describes adding a store URL. Live inspection on20Sep returned a Cloudflare human-verification screen rather than the submission form. No submission was made and no CAPTCHA bypass was attempted. Owner can complete verification manually; do not claim a listing until a confirmation exists.
5. **AppRaven:** inspected the public discovery site; no verified self-service submission path was established. No post or listing submitted. Do not guess its internal app URL from the Apple ID.

Google Search Console ownership is now verified for the owner-approved hosting account (explicitly confirmed20Sep). The URL-prefix property is `https://voicebrief-legal.vercel.app/`. Google accepted `/sitemap.xml`, shows success and10discovered pages; no resubmission is needed. Do not use Google's restricted Indexing API for ordinary app pages. Search Console and IndexNow submission receipts are not proof of indexing, ranking, downloads, or inclusion in AI responses. Do not spam retries or create an automation without a request.

## Google ownership — 2026-09-20

- The user selected the existing hosting account and explicitly approved making it the property owner. Other accounts/properties were not modified.
- Google supplied a public `google-site-verification` meta tag. It is preserved in `build_marketing_site.mjs` and rendered in the heads of `/` and `/ar`; a regression test checks both. This is public proof, not an API credential, analytics script, cookie, or tracking integration.
- Search Console Settings explicitly displayed “You are a verified owner” and valid `robots.txt`. `/sitemap.xml` submission was confirmed successful, with10discovered pages and latest read20Sep2026. The sitemap includes all10marketing pages, not a claim that all10are indexed.
- Manual Actions and Security Issues reports both showed no detected issues. These are Search Console site reports, not a security audit of the mobile app. Generative-search settings showed inherited control currently “Include”; no settings were changed. Eligibility to be included does not guarantee a citation, placement, or traffic.
- English homepage inspection: discovered via `/sitemap.xml`, not yet indexed. Exactly one manual indexing request was attempted; Google rejected it with “Quota exceeded” and instructed trying tomorrow. No indexing request was accepted and no retry/alternate-account workaround was used. The later owner-requested follow-up is documented below.
- Arabic `/ar` read-only inspection still reported URL unknown/not indexed, with no sitemap association in that inspection snapshot, despite the separate successful10-page sitemap receipt. These reports are not proof of completed crawling and can be at different processing stages. No manual request for `/ar` was sent after the daily-limit response.
- New property reports say Google is processing data and to check again in roughly a day. This is a report-processing notice, not an indexing deadline.
- Preserve the verification tag in every deployment, including rollback. Older snapshots without it can eventually invalidate ownership. No Google Analytics/Tag Manager, new users, OAuth client, paid service, or domain changes were configured.

## Scheduled indexing follow-up — 2026-09-20

At the owner's request to continue until completion, created and read back ACTIVE in-thread heartbeat `voicebrief`, named “متابعة فهرسة VoiceBrief”. Daily09:00 Asia/Riyadh; the saved prompt explicitly skips all inspection/requests before21Sep2026. The rejected manual request occurred20Sep about02:45 Riyadh; wait at least24hours after every quota failure. Do not work around limits, change owner accounts, bypass CAPTCHA, or repeatedly submit an accepted URL. At most one request per eligible URL (English `/` and Arabic `/ar`), two per run, stopping all writes immediately if Google returns a quota error. Preserve the successful sitemap and ownership proof.

Inspect both URLs, record meaningful state changes and any accepted request, and stop the heartbeat after Google confirms both indexed. Remain quiet on unchanged state; surface a new failure, required owner login/action, or confirmed progress/completion. Acceptance alone is not indexing, ranking, or AI recommendation. Do not expand to stores, emulator sessions, other directories, or paid services. The computer and desktop app must stay running and the approved Google session must remain available. The actual22Sep run and newest quota timestamp are documented at the top; use those over the historical20Sep timestamp. Existing live deployment/hash and website test results remain unchanged: this follow-up is observation/request/documentation only.

## Reusable launch copy

**Name:** VoiceBrief

**Tagline (under 60 characters):** Voice notes into summaries, dates, and next steps

**Product Hunt description (under 500 characters):**

VoiceBrief turns the audio you choose to share into transcripts, concise summaries, tasks, dates, and suggested replies. Share a WhatsApp voice note, import an audio file, or record in the app. Review the result before acting and save text on your device. Available for iPhone and iPad with 11 interface languages. Free download with limited free usage and optional Pro subscriptions. Internet and Apple or Google sign-in required.

**Maker comment:**

I’m the maker of VoiceBrief, an independent iPhone and iPad app for people who want to understand a voice note without replaying it. You choose the audio, then get a transcript and a brief with details to review. I paid particular attention to Arabic use, dates that need confirmation, and a simple sharing flow. The app also offers 10 other interface languages. Processing is cloud-based, some features require Pro, and AI output should be checked. I’d welcome feedback on the clarity of the summaries and the sharing experience.

**Arabic post:**

أطلقت VoiceBrief للآيفون والآيباد: تطبيق يحوّل الرسائل والملفات الصوتية التي تختارها إلى نص وملخص، مع مهام ومواعيد وردود مقترحة تراجعها قبل استخدامها. يمكنك مشاركة رسالة صوتية من واتساب أو استيراد ملف أو التسجيل داخل التطبيق. يدعم 11 لغة للواجهة، ومنها العربية، ويحفظ النتائج النصية التي تختارها على جهازك. التنزيل مجاني مع استخدام محدود واشتراك Pro اختياري؛ وتحتاج المعالجة إلى الإنترنت وتسجيل الدخول. جرّبه وأخبرني كيف كانت تجربة التلخيص والمشاركة.

App Store: https://apps.apple.com/app/id6805194629

Use `/press` for original screenshots and icon. Product Hunt gallery recommends 1270×760 and at least two images; existing portrait screenshots should not be misrepresented as that exact size. Adapt editorial layout if an actual submission requires it; preserve the actual app UI.

## Primary references

- https://developers.google.com/search/docs/appearance/ai-features
- https://www.indexnow.org/documentation
- https://www.producthunt.com/launch/preparing-for-launch
- https://alternativeto.net/faq/
- https://www.saashub.com/services/submit
- https://appagg.com/add/?hl=en
- https://appraven.net/
- https://apps.apple.com/us/app/voicebrief-audio-summaries/id6805194629

## Current deployment and acceptance — 2026-09-20

- Current production verification-tag deployment: `dpl_GoeWCCvpBYV73f9oBDsdek7eKysu`, READY, aliased to `https://voicebrief-legal.vercel.app`. Immutable URL: `https://voicebrief-legal-1g7lmzxh7-mhm1981x-4333s-projects.vercel.app`. Google subsequently verified the live ownership tag successfully.
- Prior content deployment: `dpl_8hA7WeQTiv8dymwq28N4sXE81oBu`, `https://voicebrief-legal-2fewxhp3k-mhm1981x-4333s-projects.vercel.app`. Preserve the new verification tag if its content is ever used for rollback.
- Public site snapshot:32non-dot files,1,334,692bytes. SHA256:`c9187e18c6c6a0c02faf1b0a7412c2de4f780aefbba121ea49006adb6a668f45`. Digest method: recursive paths normalized to `/`, lexically sorted with Node `.sort()`, each `relative/path:sha256(file)` joined by LF without a trailing LF, then SHA256. Dotfiles/directories excluded; the digest describes the public source snapshot only.
- This metadata-only update passed17Node tests and HTML validation for both modified homepages. The only generated-page diff is one non-executable meta tag per homepage; no visible UI, legal forms, native app or backend changed, so no native build/sync or new physical-device test applies. Vercel READY and Google's successful owner verification are live acceptance evidence; no direct production-page fetch was performed after deployment.
- Sixteen Node tests passed (static/localized content, reciprocal language links, identity, CSP hashes, accurate assets, sitemap, guide reachability, legal links and five mocked language cases without network). Ten pages passed `html-validate`. Browser40layout combinations at320/390/768/1440passed without horizontal overflow;8legal-to-home navigation cases plus language switch, keyboard breadcrumb and FAQ passed. Browser errors:0. No form submitted. Diff review confirmed legal content and form logic unchanged.
- Visual evidence reviewed: `output/playwright/voicebrief-marketing-20260920/ar-guide-mobile.png`, `en-guide-desktop.png`, `ar-guides-navigation.png`. Headless website captures, not physical-device/app acceptance. Prior production homepage was independently scraped HTTP200 BEFORE this change. No post-deploy page fetch; Vercel READY/alias is the current deployment evidence. Task-owned preview and browser closed.
- IndexNow POST to `https://www.bing.com/indexnow` at `2026-09-19T23:01:54.4509255Z`:14new/modified URLs (10marketing from sitemap and `/privacy`, `/terms`, `/support`, `/delete-account`), unchanged public key/location. **HTTP200**, empty response: successful submission, NOT indexing/ranking/AI inclusion. Legitimate changed-content batch, not a retry of unchanged URLs. Earlier19Sep20:50UTC batch of6received202. No new monitor or repeated retries.
- Google Search Console ownership and sitemap are complete. Product Hunt/AlternativeTo account access and AppAgg human verification remain pending; this approval only covered Google Search Console. No external directory listing, review, vote, community post, paid placement or purchase was made.

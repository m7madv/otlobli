# VoiceBrief organic discovery

## Scope and truth

The owner requested free, professional promotion of the published iPhone app on 2026-09-19. No advertising spend, paid directory placement, fabricated reviews, upvotes, downloads, or bulk unsolicited messages are authorized by this implementation. Never promise placement in search results or AI answers.

The public US App Store listing was fetched live on 2026-09-19: `VoiceBrief: Audio Summaries`, app ID `6805194629`, publisher `mohammad alzouabi`, version `0.1.2`, iPhone/iPad, iOS 14+, 11 interface languages, free download with in-app purchases. Do not conflate similarly named products or promote Google Play as publicly released without checking.

The former root of `https://voicebrief-legal.vercel.app/` redirected to privacy. The marketing build replaces only that root redirect and adds six static pages:

- `/` and `/ar`: product, actual app screenshots, App Store download, limitations, FAQs.
- `/guides/whatsapp-voice-notes` and `/ar/guides/whatsapp-voice-notes`: practical sharing instructions without promising unsupported direct app launch.
- `/press` and `/ar/press`: publisher, app ID, factual directory copy, icon, and screenshots.

Existing privacy, terms, support, deletion, forms, and their JavaScript remain unchanged. No native code, subscriptions, backend processing, prices, or App Store metadata changed.

## Design and implementation

Preserve the existing Obsidian Monochrome + Signal Blue identity. Tokens: white `#fff`, ink `#090909`, secondary `#636366`, surface `#f5f5f7`, border `#d1d1d6`, accessible link blue `#0066cc`. Platform sans fonts for body/display, restrained monospace for the actual three-step sequence. Product imagery is the signature, not invented testimonials or AI-generated interfaces.

The UI/UX skill search suggested product demo + features/minimalism. We adopted that structure, not its unrelated red palette or external Inter font. Existing brand decisions take precedence. Semantic HTML works without JavaScript, Arabic uses RTL and separate canonical URLs, images have fixed dimensions and below-fold lazy loading. No analytics, cookies, extra runtime dependencies, third-party requests, background polling, or animation.

Eight screenshots are copied byte-for-byte from `store_assets/localized/{en,ar}/iphone`, generated from production Flutter widgets with synthetic sample content. They are not physical-device captures. No image generation was needed.

`scripts/build_marketing_site.mjs` generates HTML, sitemap/hreflang, robots, machine-readable public facts, and hashes the JSON-LD scripts for the existing strict CSP. It copies only selected public assets. The IndexNow ownership file is public by design and is created once, not rotated on each build. No special AI file, prompt injection, invented rating schema, or claim of guaranteed AI citation.

Build/check:

```text
node voicebrief_flutter/scripts/build_marketing_site.mjs
node --test voicebrief_flutter/scripts/marketing_site_test.mjs
node voicebrief_flutter/scripts/preview_marketing_site.mjs
```

The preview is loopback-only on port 4179 and accepts GET/HEAD only. Marketing output is plain static HTML/CSS, not the unrelated Otlobli customer web bundle; mobile synchronization/builds are not applicable.

## Free distribution channels checked

1. **Product Hunt:** free submission through the owner's personal account. `/posts/new` currently returns a sign-in page. Use the kit below, acknowledge the maker relationship, and ask for genuine feedback, never upvotes. Not submitted until a confirmation exists.
2. **AlternativeTo:** requires an account; free submissions are moderated and can wait without a promised review time. English UI is supported, so VoiceBrief meets that language prerequisite. A similarly named listing must not be claimed as ours. Not submitted until a confirmation exists.
3. **SaaSHub:** its current submission rules reject products using free subdomains, including Vercel-style ones. Do not submit this free-hosted website there or buy a domain without owner approval.

Google Search Console requires verified owner access to submit/inspect the sitemap and request indexing. Do not use Google's restricted Indexing API for ordinary app pages. IndexNow receipts acknowledge URL submission, not indexing, ranking, downloads, or inclusion in AI responses. One submission is enough; do not spam retries or create an automation without a request.

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
- https://apps.apple.com/us/app/voicebrief-audio-summaries/id6805194629

## Deployment and acceptance

- Production deployment succeeded on 2026-09-19: `dpl_FufzDD2AZgWoXQTXdoAALnuj3XPg`, READY, aliased to `https://voicebrief-legal.vercel.app`. Immutable deployment URL: `https://voicebrief-legal-ao6uymfle-mhm1981x-4333s-projects.vercel.app`.
- Previous production for rollback, not modified: `https://voicebrief-legal-agpxxxmzg-mhm1981x-4333s-projects.vercel.app`.
- Public site snapshot: 28 non-dot files, 1,274,446 bytes. SHA256 of sorted `relative/path:sha256(file)` lines joined by LF (no trailing LF): `d0fa84eb890b7fbdec41d4591fe77f4d78471edb9bb6aa0f60e75d09dcc9bb5c`. Paths are lexically sorted using Node's `.sort()` after recursive enumeration and normalized to `/` in the digest input.
- Nine Node static/identity/link/CSP/asset/SEO tests passed. All six pages passed `html-validate`. Browser layout checks passed on all six at 320, 390, 768, and 1440px (24 combinations, no horizontal overflow). English/Arabic image decoding and keyboard FAQ interaction passed; language switching was exercised. Eight local legal-page/language cases returned 200 and applied the correct locale. Browser console: no errors or warnings. No real iPhone/iPad acceptance or production-page fetch was performed in this deployment step; deployment confirmation comes from Vercel's READY/alias response.
- Visual evidence: `output/playwright/voicebrief-marketing-20260919/en-final.png` and `ar-final.png`, inspected by the agent. These are headless-browser website captures, not app/device acceptance.
- IndexNow POST to the verified Microsoft Bing endpoint `https://www.bing.com/indexnow` at `2026-09-19T20:50:43.1575807Z` included exactly the six public pages with the hosted ownership file. Response **202**, empty body: URLs received, ownership-key validation pending. This is NOT proof of indexing, ranking, or inclusion in AI answers. No retry spam and no new monitor.
- Google Search Console ownership/sitemap submission and account-gated Product Hunt/AlternativeTo listings remain pending. The user was asked whether they have an account. No external listing, review, upvote, or community post was published. SaaSHub was deliberately not submitted because its rules reject free subdomains. No paid action taken.

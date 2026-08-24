# Design audit

Reviewed on 2026-08-24 against the pinned Apple Design Skill commit `d0bac1e765a27a696839e62962e36330ce72f0b7`, especially accessibility, color, layout, typography, motion, privacy, generative AI, RTL, onboarding, loading, feedback, account management, data entry, in-app purchase, and audio playback references.

## Resolved findings

- **High — narrow authentication action overflow:** Google action now reserves symmetric brand slots and lets its label flex.
- **High — subscription option overflow:** title/badge wrap and the localized price lives inside the flexible content column.
- **High — large-text action overflow:** primary/secondary actions use minimum height and flexible text instead of a fixed 52-pixel box.
- **High — large-text error overflow:** error state is centered in a scrollable constrained layout.
- **Privacy:** original audio is never represented as saved history; Settings explains temporary processing; transcript and generated brief remain visibly separate.
- **Generated-content clarity:** result hierarchy labels the generated Brief separately from the word-for-word transcript, explains the distinction, keeps the transcript collapsed by default, preserves uncertain spoken date phrases, and requires confirmation before opening calendar UI.
- **Loading:** processing uses truthful named stages with no fabricated percentage.
- **Dark mode/contrast:** exact light/dark palettes and non-color status labels are present.
- **Platform behavior:** Material navigation and controls remain Android-appropriate; Apple/Google sign-in use platform/provider components.
- **Direct-share discoverability:** Home now teaches the WhatsApp flow in one compact guide instead of a tall three-step card, and a shared note lands on a dedicated ready state with one primary `Create my brief` action.
- **System language and direction:** Arabic and English now cover the complete application chrome. An Arabic system locale selects Arabic with RTL layout; every non-Arabic system locale selects English with LTR layout.
- **Note 8 hierarchy:** the Home screen was reduced to one headline, a compact WhatsApp guide, two clear audio actions, quota, and recent results. The full primary flow remains visible on the 1080x2220 Android 9 viewport without clipping.
- **Microphone privacy:** the system permission is requested just in time after the user taps the record control, not at launch or navigation time. Denial remains non-destructive and the button is re-enabled after failures.
- **Sound-reactive recording feedback:** the recorder now converts the package's real dBFS samples to perceptual visual levels, applies fast attack and slower release, and gives every update an immutable painter snapshot. This fixes the old shared-list identity bug that could leave all bars visually frozen after the first repaint. The live canvas mirrors chronologically in RTL, uses text and an icon in addition to color, isolates frequent paints inside `RepaintBoundary`, and avoids continuous haptics that could contaminate microphone input.
- **Recorder action clarity:** the unlabeled circular record control is now a full-width, 56-pixel action with both microphone icon and localized `Start recording` text. Status, timer, and waveform are grouped into one quiet surface, while pause, stop, and cancel remain separately labeled.
- **Progressive disclosure:** optional output controls moved under an advanced expander so the common share-to-brief path remains one obvious decision.
- **Date review:** a non-color-only banner announces detected dates; calendar actions are attached to both important dates and dated tasks, with confirmation before the native editor opens.
- **Imported-audio control:** the preparation screen now exposes a real extracted waveform, a seekable time slider, tap/drag waveform seeking, and a two-ended trim range. The selected duration is always written next to the controls, the full recording can be restored with a labelled action, and processing clearly says it will summarize the selected part.
- **Responsive audio feedback:** waveform extraction reports progress without blocking playback, seeking, Back, or trimming. The audio button, slider, range handles, reset action, and processing state all have visible and semantic feedback; frequent waveform paints stay isolated from the rest of the screen.
- **Deletion recovery:** History removes a dismissed result optimistically instead of waiting on storage, immediately confirms deletion, and exposes a labelled Undo action. Deleting from Result navigates away immediately after confirmation instead of leaving a frozen-looking screen.

The cross-platform portions of Vercel's current Web Interface Guidelines were also applied: specific action labels, minimum touch targets, semantic labels for icon actions, visible asynchronous state, safe areas, long/empty content handling, locale-aware date formatting, and no gesture-only path. Web-only DOM/ARIA rules are not applicable to Flutter semantics.

Eight visually reviewed golden baselines cover light/dark authentication, light/dark home, processing, the date-aware result, paywall, and 1.6x large text. They pass after the resolved layout fixes.

Physical-device evidence on `SM_N950F` / Android 9 is stored under `output/voicebrief/design-audit-note8/`: `home-after.png` shows the Arabic RTL Home layout and `10/10` allowance, `history-centered.png` shows the empty History state centered without right-edge clipping, `mic-permission-after.png` shows the Arabic Android microphone prompt, and `waveform-live-1.png` plus `waveform-live-2.png` prove that the recorder bars react to sound. `audio-editor-imported.png` and `audio-editor-waveform.png` show the imported-file editor before and after real waveform extraction. `history-before-delete-final.png` and `history-after-delete-final.png` show the saved result and its immediate removal with Undo. On the same device, a 2:46 extensionless provider MP3 was imported, waveform seeking reached 2:29, the slider reached 1:34, the range was set to 0:42–1:11, and a real 0:29 M4A reached Result within the bounded 15-second wait. A single Back after picker import returned to Home.

## Verification still requiring devices

- VoiceOver rotor/focus order, Dynamic Type at every accessibility category, Reduce Motion, and iOS contrast on a real device.
- TalkBack traversal, switch access, display-size scaling, and font scaling at 200% on Android hardware. Arabic RTL, the default Note 8 scale, just-in-time microphone permission, active recording, imported waveform/seek/trim, Back navigation, optimistic deletion, and Undo are physically verified.
- Landscape/tablet polish is supported by constraints but not a first-release primary layout.
- The iOS Runner and embedded Share Extension now compile and package through Xcode on GitHub macOS. VoiceOver, calendar interaction, Share Extension/App Group handoff, waveform/seek/trim interaction, signing, and physical-iPhone acceptance are still required; a successful unsigned build is not substituted for those device checks.

No critical or high-severity source finding remains. Device-only items are release gates, not claimed as completed.

## Public legal and support pages

The bilingual pages were reviewed against the same pinned Apple references for accessibility, color, layout, typography, privacy, writing, dark mode, and help, plus Vercel's current Web Interface Guidelines. They use semantic landmarks and heading order, a visible skip link/focus state, labelled form controls, a keyboard-first path, live support status, system fonts, responsive RTL/LTR layouts, 48-pixel controls, reduced-motion handling, and light/dark contrast-adjusted colors. `html-validate` reports no errors. A local Arabic dark-mode render was visually inspected at 1280×720. Narrow CSS behavior is implemented but a separate captured 390-pixel browser proof remains desirable.

Supabase's HTML gateway overrides custom styling with a restrictive CSP, so the formatted public pages are hosted free on Vercel while the support write endpoint remains on Supabase. The Edge Function fallback stays semantic and usable even without the Vercel layer.

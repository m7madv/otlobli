# Accessibility audit

## Completed in source/tests

- 48-pixel icon targets and minimum 52-pixel action height; actions expand vertically for large text.
- Semantic labels/roles for waveform, playback progress, current processing step, usage, subscription selection, delete action, and icon tooltips.
- Native text controls, logical source order, autofill, keyboard actions, password visibility label, and scrollable keyboard-safe authentication.
- Exact contrast-oriented light/dark palettes; errors and states use text/icons in addition to color.
- Directional alignments/padding and localization delegates establish RTL support.
- No required gesture-only action: swipe-delete also corresponds to clear/delete controls elsewhere; calendar uses explicit confirmation.
- Animations are short and informational state remains understandable without motion or haptics.
- Golden/widget tests cover light/dark, a 1.6× home, and a 2× dark error state. Layout overflows found during the audit were fixed.

## Release device gates

- Android TalkBack: traversal order, action labels, password feedback, navigation selection, recorder/playback controls, dialogs, paywall selector, and date confirmation.
- Android: font scale 200%, display-size increase, switch access, and keyboard/external input.
- iOS VoiceOver: rotor order, provider buttons, Share Extension alert/success, player state, result sections, calendar confirmation, and delete dialog.
- iOS: all Dynamic Type accessibility sizes, Bold Text, Increase Contrast, Reduce Transparency, Reduce Motion, and Voice Control.
- Verify contrast with captured release pixels, including disabled controls and selected plan borders.

Device checks were unavailable on iOS here and must not be marked complete from goldens alone.

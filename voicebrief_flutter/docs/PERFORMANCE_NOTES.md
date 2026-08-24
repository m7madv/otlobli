# Performance notes

- Riverpod selectors limit rebuilds for theme, subscription, history, result, and error state.
- Home displays only three recent items; history uses `ListView.separated` lazy construction and Drift streams.
- Waveforms are deterministic `CustomPainter` bars with repaint comparison, not frame-by-frame FFT work.
- Screens avoid blur, gradients, large shadows, nested effects, autoplay, persistent timers, and decorative animation.
- Recorder amplitude sampling is bounded to 120 ms and its UI timer exists only while recording.
- Files are capped at 25 MB. Native share copies stream in fixed buffers. Production upload should use the Supabase file upload API rather than loading extra transformed copies; no FFmpeg binary is included.
- Result lists remain lazy at screen level, but a single extremely long selectable transcript is still one text layout. Profile real multi-hour transcripts; introduce chunked transcript paragraphs only if traces show a measurable issue.
- Temporary players/recorders/subscriptions are disposed; audio files are cleaned after terminal processing.

## Profiling gates

On a release/profile build, measure cold/warm launch, import of 25 MB audio, recorder amplitude, processing transition, large transcript scroll, history search with realistic rows, theme switch, background/resume, and memory after repeated processing. Test on a weak/old Android device in addition to the emulator. No device-profile numbers are claimed from source analysis.

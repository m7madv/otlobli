# Performance notes

- Riverpod selectors limit rebuilds for theme, subscription, history, result, and error state.
- Home displays only three recent items; history uses `ListView.separated` lazy construction and Drift streams.
- Waveforms are deterministic `CustomPainter` bars with repaint comparison, not frame-by-frame FFT work.
- Screens avoid blur, gradients, large shadows, nested effects, autoplay, persistent timers, and decorative animation.
- Recorder amplitude sampling is bounded to 120 ms and its UI timer exists only while recording.
- Files are capped at 25 MB. Native share copies stream in fixed buffers. Production upload should use the Supabase file upload API rather than loading extra transformed copies; no FFmpeg binary is included.
- Result lists remain lazy at screen level, but a single extremely long selectable transcript is still one text layout. Profile real multi-hour transcripts; introduce chunked transcript paragraphs only if traces show a measurable issue.
- Temporary players/recorders/subscriptions are disposed; audio files are cleaned after terminal processing.
- The client sends a validated `ar`/`en` language hint from the system locale to the transcription endpoint. The production candidate uses `gpt-4o-mini-transcribe`, which is cheaper and intended for low-latency transcription; exact device/network latency must still be measured after deployment.
- `process-audio` records privacy-safe stage timings for storage download, transcription, summarization, and total processing. Logs contain only a short job hash, model name, and millisecond durations—never file names, audio, transcript, or generated text.
- Arabic transcription prompting preserves spoken number/date wording so the summary stage receives `يوم خمسة تسعة` instead of a guessed time.
- Production measurement on 2026-08-30 uses `gpt-4o-mini-transcribe` plus `gpt-5.6-luna` with low reasoning effort and low verbosity. For the same `24.096s` Arabic sample, function time dropped from `19,717ms` to `11,282ms` and client time from `21,066ms` to `14,431ms`, while the two expected dates and confirmation flags remained correct. Final stages: download `1,330ms`, transcription `1,460ms`, summary `7,177ms`.

## Profiling gates

On a release/profile build, measure cold/warm launch, import of 25 MB audio, recorder amplitude, processing transition, large transcript scroll, history search with realistic rows, theme switch, background/resume, and memory after repeated processing. Test on a weak/old Android device in addition to the emulator. No device-profile numbers are claimed from source analysis.

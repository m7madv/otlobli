# Design system

The visual identity is **Obsidian Monochrome + Signal Blue**. It relies on typography, alignment, separators, and a compact waveform signature—not decoration. During recording, that signature is driven by real dBFS samples with a fast rise and controlled release rather than a decorative loop.

## Tokens

- Light: `#FFFFFF` background, `#090909` primary text, `#636366` secondary text, `#F5F5F7` surface, `#E5E5EA` border, `#007AFF` accent.
- Dark: `#000000` background, `#F5F5F7` primary text, `#98989D` secondary text, `#0D0D0F` surface, `#2C2C2E` border, `#0A84FF` accent.
- Spacing follows 4/8/12/16/20/24/32/40 logical pixels, with 20-pixel page padding.
- Controls use at least 48 logical pixels; primary components use 12–16 pixel radii.
- Typography uses the platform system font. No SF font files are bundled. The 32/28/22/17/16/15/13/12 scale supports system text scaling.
- Motion is 160–220 ms, ease-out, and never required to understand state.

Signal Blue is limited to primary action, active navigation, selected plans, progress, waveform state, links, and focus. There are no gradients, glows, glass cards, decorative blobs, AI sparkles, fake testimonials, or urgency devices.

## Responsive rules

- Directional alignment/padding supports RTL.
- Locale resolution follows the operating system: Arabic locales use the complete Arabic RTL interface; all other locales use the complete English LTR interface.
- Long pages use lazy/scrollable layouts and safe areas.
- Buttons use minimum height rather than fixed height so large text can expand.
- Subscription rows wrap badges and place price below the title on compact widths.
- Errors become vertically scrollable while remaining centered when space permits.
- Avoid nested cards; use whitespace and `AppDivider` between result sections.

## Components

The reusable component inventory requested by the product brief is implemented in `lib/ui/core/components/app_components.dart`, including scaffolds, bars, actions, fields, segments, list rows, dialogs/sheets/toasts, state views, audio visuals, processing steps, result sections, reply tiles, subscription tiles, and badges.

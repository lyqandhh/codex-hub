# Codex HUD Design QA

- Source visual truth: `/Users/mantou/.codex/generated_images/019f594b-489e-7c63-8e1a-fb9ba95e914e/exec-097c49b1-c6ae-4134-a700-c50d28154be6.png`
- Implementation screenshot: `qa/hud-v2.jpeg`
- Combined comparison: `qa/comparison-v2.png`
- Viewport: 390 × 52 pt HUD window
- State: live quota, 98-99% weekly remaining, 3 reset credits, July 20 reset

## Full-view comparison evidence

The selected reference and implementation are shown together in `qa/comparison-v2.png`. Both use a single slim horizontal capsule, high-contrast numeric hierarchy, lightweight separators, a right-side live status dot, and a bottom quota meter. The implementation intentionally replaces the obsolete 5-hour/7-day pair with the current weekly quota, reset-credit count, and reset date while preserving the selected visual density.

## Focused-region comparison evidence

No additional crop is required because the rendered artifact is itself a 390 × 52 component capture; typography, separators, status dot, border, background, and the complete meter are readable at original size in the combined comparison.

## Required fidelity surfaces

- Fonts and typography: system rounded typography matches the native macOS utility character. Weekly percentage remains the strongest element; metadata is smaller and lower contrast without becoming unreadable.
- Spacing and layout rhythm: 18 pt horizontal padding and 15 pt inter-group spacing keep all three current data points in one scan line. The 18 pt continuous radius maintains the selected pill silhouette.
- Colors and visual tokens: dark graphite surface, cool white text, green live indicator, and green-yellow-orange quota line match the selected direction. Low-quota warning colors are semantic and restrained.
- Image quality and asset fidelity: the HUD contains no raster illustrations, logos, or decorative image assets. Native vector shapes are appropriate for the progress meter, separators, and status indicator.
- Copy and content: `1周 99% · 重置 ×3 · 7月20日` reflects the current Codex product model and the user's live account data.

## Comparison history

### Iteration 1 — blocked

- P2: the initial material surface became too light on a pale desktop, reducing text contrast.
- P2: the quota line was a flat green instead of the selected green-yellow-orange treatment.
- Evidence: `qa/hud-v1.jpeg` and `qa/comparison-v1.png`.

Fixes:

- Added a stable graphite overlay above the native visual-effect material.
- Increased secondary-text contrast.
- Replaced the flat line with a restrained green-yellow-orange linear meter while retaining the low-quota orange-red state.

### Iteration 2 — passed

- Evidence: `qa/hud-v2.jpeg` and `qa/comparison-v2.png`.
- No actionable P0, P1, or P2 visual differences remain.

## Interaction evidence

- Live accessibility text reported `Codex 本周剩余 99%，重置 ×3，7月20日重置` and later refreshed to 98%.
- Right-click menu exposed refresh, mouse passthrough, opacity, login launch, reset position, and quit.
- Mouse passthrough was enabled, then successfully recovered with Command-Shift-H; the menu returned to `开启鼠标穿透`.

## Follow-up polish

- P3: a future signed distribution build may add a custom Finder icon; it does not affect the hidden-Dock HUD experience.

final result: passed

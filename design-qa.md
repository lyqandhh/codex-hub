# Codex HUD Design QA

- Source visual truth: `/Users/mantou/.codex/generated_images/019f594b-489e-7c63-8e1a-fb9ba95e914e/exec-fc554883-ce19-460e-adeb-b5cb4713e232.png`
- Implementation screenshot: `qa/micro-hud.jpeg`
- Combined comparison: `qa/micro-comparison.png`
- Viewport: 118 × 30 pt HUD window
- State: live quota, 97% weekly remaining, 3 reset credits, July 20 reset

## Full-view comparison evidence

The selected micro-ring reference and implementation are shown together in `qa/micro-comparison.png`. Both use a tiny graphite capsule, a left quota ring, a two-line reset-credit/date stack, and a right-side live status dot. The implementation occupies 3,540 square points versus the previous 20,280 square points, a reduction of approximately 82.5%.

## Focused-region comparison evidence

No additional crop is required because the rendered artifact is itself a 118 × 30 component capture. The combined comparison enlarges both artifacts equally enough to inspect ring stroke, numeric centering, two-line spacing, date legibility, status dot, border, and surface treatment.

## Required fidelity surfaces

- Fonts and typography: system rounded typography matches the native macOS utility character. The ring value is strongest, `×3` is secondary, and `7/20` is quiet but remains readable at native scale.
- Spacing and layout rhythm: 8 pt outer padding, a 26 pt ring, an 8 pt gap, a 30 pt two-line stack, and a 6 pt state dot fit without clipping. The 15 pt radius produces the selected micro-pill silhouette.
- Colors and visual tokens: dark graphite surface, cool white text, semantic quota-ring colors, and a green live indicator match the selected direction without the redundant bottom gradient.
- Image quality and asset fidelity: the HUD contains no raster illustrations, logos, or decorative image assets. Native vector shapes are appropriate for the progress meter, separators, and status indicator.
- Copy and content: `97`, `×3`, and `7/20` preserve all live product data while removing redundant labels and punctuation.

## Comparison history

### Micro redesign — passed

- Evidence: `qa/micro-hud.jpeg` and `qa/micro-comparison.png`.
- The permanent footprint was reduced by approximately 82.5%.
- No actionable P0, P1, or P2 differences remain; the generated presentation mock has looser padding, but the implemented 118 × 30 dimensions follow the explicitly approved specification and remain legible.

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

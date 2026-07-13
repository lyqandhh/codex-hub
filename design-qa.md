# Codex HUD Design QA

- Source visual truth: `/var/folders/4d/t48gkmhj47n6nxcf_m7mbdkc0000gp/T/codex-clipboard-27341380-58de-4edf-a125-0d7f234b2910.png`
- Implementation screenshot: `qa/aspect-fixed-hud.jpeg`
- Combined comparison: `qa/aspect-comparison.png`
- Viewport: 118 × 46 pt HUD window
- State: live quota, 96% weekly remaining, 3 reset credits, July 20 reset

## Full-view comparison evidence

The user-provided design crop and corrected implementation are shown at the same height in `qa/aspect-comparison.png`. Both now use an approximately 2.56:1 rounded rectangle, a left quota ring occupying about 70% of the height, a two-line reset-credit/date stack, and a right-side live status dot. The corrected implementation occupies 5,428 square points versus the original 20,280 square points, a reduction of approximately 73.2%.

## Focused-region comparison evidence

No additional crop is required because the implementation is a direct 118 × 46 component capture and the user-provided design was cropped to its exact visible widget bounds. Both are normalized to 133 px height in the combined comparison.

## Required fidelity surfaces

- Fonts and typography: system rounded typography matches the native macOS utility character. The ring value is strongest, `×3` is secondary, and `7/20` is quiet but remains readable at native scale.
- Spacing and layout rhythm: 10 pt outer padding, a 32 pt ring, 10 pt gaps, a compact two-line stack, and a 7 pt state dot fit without clipping. The corrected 118 × 46 frame matches the approved design's visible aspect ratio.
- Colors and visual tokens: dark graphite surface, cool white text, semantic quota-ring colors, and a green live indicator match the selected direction without the redundant bottom gradient.
- Image quality and asset fidelity: the HUD contains no raster illustrations, logos, or decorative image assets. Native vector shapes are appropriate for the progress meter, separators, and status indicator.
- Copy and content: `97`, `×3`, and `7/20` preserve all live product data while removing redundant labels and punctuation.

## Comparison history

### Transparent-corner correction — passed

- Earlier finding: the AppKit visual-effect hosting surface was not masked, leaving a rectangular gray backing visible outside the SwiftUI rounded capsule.
- Root cause evidence: the hosting layer reported `masksToBounds=false`, `cornerRadius=0`, and no explicit clear background.
- Fix: configured the native `NSHostingView` layer with a clear background, 18 pt continuous corner radius, and `masksToBounds=true`.
- Post-fix evidence: `qa/transparent-corners.jpeg`; the four outer corners now reveal the underlying screen instead of a gray rectangle.
- Automated regression: `FloatingPanelTransparencyTests.hostingSurfaceMasksVisualEffectToRoundedCorners`.
- No actionable P0, P1, or P2 transparency issues remain.

### Aspect-ratio correction — passed

- Earlier finding: the approved visual was approximately 2.55:1, while the first implementation was 118 × 30 or 3.93:1, producing an overly flat and wide chip.
- Root cause: implementation followed numeric dimensions written in the generation prompt even though the generated visual did not render those proportions.
- Fix: changed the window to 118 × 46, the ring to 32 pt, and scaled typography and spacing to the corrected height.
- Post-fix evidence: `qa/aspect-fixed-hud.jpeg` and `qa/aspect-comparison.png`.
- No actionable P0, P1, or P2 aspect or sizing differences remain.

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

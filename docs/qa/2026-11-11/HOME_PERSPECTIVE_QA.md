# Homepage cursor perspective — 2026-11-11

## Change

- A shared, exponentially eased viewport cursor drives the hero and space background.
- Hero artwork is projected through X/Y plane rotations with perspective-correct texture coordinates. Atlas regions stay clipped to their own source image.
- Near cards/dice move farther than the planet; three procedural star layers move at separate depths. The lower sphere changes surface angle, lighting and horizon position, while preserving its slow idle rotation.
- UI labels and controls remain fixed. Decorations ignore input. Window exit targets the neutral camera; focus loss resets it and stops processing. Browser reduced motion is sampled when Home opens.
- This is projected layered artwork plus a procedural sphere, not a freely orbitable scene of modeled objects.

## Verification

- Godot 4.6.1 import and Web release export completed successfully via `tools/build_web.ps1`; import/export logs contained no `SCRIPT ERROR` or `ERROR:` entries. Build transcript: `.web-tools/home-perspective-build.log`.
- Tested final Web export at `http://127.0.0.1:8060/` in the in-app browser, 1280 × 720.
- Cursor positions near lower-left (18,705) and upper-right (1258,92) visibly changed card perspective, foreground separation, stars and the lower planet. The full card artwork remained in view; the headline and buttons stayed fixed.
- Moving over the left copy/footer area also moved the camera, confirming it is no longer limited to the hero's hover bounds.
- Home Play CTA opened the Local/Online choice screen. Home navigation recreated the animated scene correctly.
- Browser error/warning log was empty after final navigation and motion checks.
- Independent code review checked projection/atlas math, input handling and scene lifetime. Removed duplicate per-frame hero pose updates identified in review.

Evidence: `perspective-left.png`, `perspective-right.png`, `home-perspective.png`.

Scope: homepage presentation only. Online gameplay, database writes, live OS reduced-motion changes and a measured FPS benchmark were not part of this check. Focus/reduced-motion paths were reviewed in code; no browser preference was changed.

Implementation reference: [Godot CanvasItem shader built-ins](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html).

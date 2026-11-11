# Home motion verification

The owner requested pointer-responsive pieces in the hero and a slowly rotating lower planet even with no mouse movement.

## Implementation

- Original-style transparent assets split into a planet layer and a 2×2 card/dice atlas. Each component has its own gentle drift, rotation and smoothed pointer offset.
- `HomeHeroArt.gd`: six decorative layers, no input capture and no per-frame node/tween allocation. The foreground moves farther than the background; pointer exit eases back to neutral.
- `HomeSpaceBackground.gd`: slowly rotating projected planet surface, clouds, faint lights, rim highlight and gentle star twinkle.
- Motion belongs only to Home, pauses on window focus/visibility loss and honors the browser reduced-motion preference when Home opens. Other pages keep their existing static background.

## Verified

- Godot 4.6.1 import/Web export passed with no script errors.
- Actual WebGL browser render at 1280×720: no shader errors or captured console warnings/errors.
- Pointer movement across the image visibly tilts/shifts separate cards and dice; headings and buttons remain stationary.
- Two screenshots with the pointer held outside the illustration confirm idle motion: lower-planet ROI mean pixel change 7.1319/255 versus headline ROI 0.0033/255. This is a motion check, not a performance benchmark.
- Play CTA still opens the mode chooser; returning Home recreates the animation correctly and restores its dark navigation backdrop.
- Screenshots: `home-motion.png`, `motion-idle-a.png`, `motion-idle-b.png`.

No gameplay/network logic or production database data changed. Reduced-motion preference changes require reopening Home/reloading. No low-end-device FPS benchmark was performed.

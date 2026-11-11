# Central planet animation — 2026-11-11

## Change

- Added a dedicated planet shader; card animation remains on the existing perspective shader.
- The canyon globe has stronger slow roll/precession, elliptical floating motion and a subtle scale cycle.
- A luminous head and tapered tail follow the illustrated orbit (about 22 seconds per idle circuit). Hover eases the speed up by at most 35%, without resetting phase.
- Bright water inside the waterfall corridor shimmers downward. Cliff geometry and texture coordinates are not warped.
- The terrain masks the far orbit. Alpha compositing also works outside the opaque planet; the outer ring is excluded from the terrain mask.
- Motion uses the existing paused elapsed clock and reduced-motion setting. No input-catching overlay or extra process node was added.

## Verification

- Godot 4.6.1 import/Web export succeeded; no script or export errors in import/export logs. Transcript: `.web-tools/home-planet-build.log`.
- Web preview checked at `http://127.0.0.1:8060/`, 1280 × 720. The moving light appeared on the exposed ring, and the planet continued changing pose with a stationary cursor over it.
- Paired evidence: `planet-motion-a.png` and `planet-motion-b.png`; final page: `home-planet-motion.png`.
- Create CTA opened the creator choices; Home navigation recreated the animated planet. Browser warning/error log was empty after these checks.
- Independent code review found no blocking shader, compositing or lifecycle issue. Focus and reduced-motion behavior were reviewed in code, not tested by changing browser preferences.

Limits: the original two beads are baked into the illustration and stay attached to it; the traveling feature is a new light. Hover uses an approximate elliptical silhouette. This is a presentation-only check, not a gameplay/database regression or FPS benchmark.

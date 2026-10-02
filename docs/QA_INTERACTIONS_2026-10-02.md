# Online interaction fixes and visual refresh — 2026-10-02

## Reported symptoms and causes

- Dice were layout-locked in play mode, and DraggableControl returned before processing their click. Locked dice now accept clicks while retaining their position.
- Rotation handles changed only the local node. Rotation now sends component state during motion (up to 20 Hz) and on release.
- Cards dragged from a hand used coordinates relative to a different parent; Guest views also rotate the board. Drops now use the inverse board transform and a common board coordinate system.
- Spawn and restored-scene callbacks could both connect to drag signals. Bound callables now allow duplicate-connection checks.
- Remote move messages could refer to cards absent from the other player's public board. Component updates include card data, dimensions, face state and rotation so the receiver can create missing cards.
- Private-hand cards returned to a shared deck were absent remotely. Return operations now synchronize the resulting draw pile as well.
- TextureRect accepted the image's native minimum size before ignore-size mode was set. That could render huge cards. Ignore-size mode is now set before assigning textures in both tabletop and field creator.

## UI

Shared forest-green theme, rounded translucent panels, green interaction accents, subtle board grid, teal card zones, green dice, gold counters, centered counter values and a clearer hand bar. Applied to the main menu, tabletop, field creator, card/deck editors and room list. This is a glass-inspired treatment using opacity and borders; it does not implement backdrop blur.

## Verification

- Local scene regression: **13/13 passed**.
- Two separate Godot clients using an ephemeral Supabase Realtime channel: **22/22 passed**.
- Interaction cases include a Guest hand drop on the rotated board, one drag callback, remote position/rotation agreement, rotation-handle input, locked-dice mouse input, hand privacy, replay and private-card return to the deck.
- Rendered the real Godot scene using the OpenGL renderer; card dimensions stayed 150 × 210 before and after layout. Screenshot: `qa/2026-10-02-interactions/ui-preview.png`.
- No SCRIPT ERROR or ERROR in final runs. Local fixture emits warnings about Image.load on a res:// image; online fixture reports ObjectDB instances at shutdown. Export behavior and shutdown resource cleanup are not certified by these tests.
- Tests invoke input handlers programmatically. They do not certify manual mouse picking, simultaneous competing moves, packet loss, every asset-selector workflow, or a packaged export.
- Earlier broad QA missed the input-specific defects above; passing transport tests alone was insufficient evidence of complete gameplay behavior.
- No production database rows were changed for this follow-up, and no push was performed. Both players must restart with the updated client to use the new component-state messages.

Evidence is under `qa/2026-10-02-interactions`; runnable fixtures are under `tests`.

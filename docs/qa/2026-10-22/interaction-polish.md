# Interaction and UI polish

Implemented orange/black glass button feedback and page fades, interruptible card/deck flip visuals, 180 ms hand layout animation, stable dice animation on visual children, drag outline/shadow, and 60 ms remote pose interpolation with exact final positions. UI animations are node-bound and replace their prior tween.

Field Creator: Ctrl+Z Undo; Ctrl+Shift+Z / Ctrl+Y Redo; alignment guides with a 7-screen-pixel threshold; Alt bypass; Shift axis lock; temporary copy/paste/delete feedback. History is capped at 50 snapshots and is inactive in gameplay/Test Mode and text inputs. It covers board edits, not external file/database saves.

Help: six selectable lessons, previous/next navigation, interactive drag/drop/flip/dice practice, completion feedback and reset. The practice explicitly explains that the actual tabletop uses the right-click menu to flip.

Validation on Godot 4.6.1:
- Hand orientation: 40/40.
- Deck selection/dice style: 13/13.
- Deck flip/help navigation: 16/16.
- Inspector images: 8/8.
- Editor selection: 20/20.
- Interaction polish: 17/17.
- Two clients on an ephemeral Realtime QA channel: 25/25 (no database room writes).
- A single history capture with 52 components measured 1.595 ms on this machine. This is not a general frame-rate benchmark or a guarantee for large fields/slow networks.
- Rendered Help screenshot inspected at 1761x991, using the compatibility renderer on Intel UHD Graphics.

Production schema and room cleanup deployment were not changed. Changes are not pushed.

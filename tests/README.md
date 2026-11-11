# Regression tests

Web import validation: `res://tests/browser_images.tscn` expects
`BROWSER_IMAGES_RESULT 14/14` in an isolated native QA project. This verifies the
shared image-byte import path; it does not replace browser file-chooser testing.
Browser verification and remaining scope: `docs/qa/2026-11-04/WEB_PREVIEW.md`.

Use Godot 4.6.1 and an isolated copy of the project (including uncommitted code),
with a separate `config/name` to avoid changing the developer's user data.

Local assertions:

```powershell
& $Engine --headless --path $IsolatedProject --max-fps 60 --quit-after 1800 --log-file "$Results/local.log" res://tests/regression.tscn -- "qa-results=$Results"
```

Expect `REGRESSION_RESULT 13/13`, exit 0, and no `SCRIPT ERROR` / `ERROR` lines.
The frame limit is a watchdog; a timeout exit without the result marker is a failure.
The test loads real scenes, uses local card/deck/field files, and may read online asset metadata/images.

Online transport assertions:

```powershell
./tests/run_online.ps1 -Engine $Engine -Project $IsolatedProject -Results $Results
```

Expect `ONLINE_RESULT 36/36`. This starts two headless Godot processes, connects
to a unique temporary Supabase Realtime channel, and closes both processes afterward.
It does **not** create or update database rows. `exit_button` clears the fixture room ID
before invoking the real button, so SQL leave behavior is explicitly outside this test.

Database permission/password/lifecycle tests are in `supabase/verify_rooms.sql`.
They require schema review, production-write approval, and the migration first.
Do not interpret successful transport tests as successful production room-RPC tests.

Manual `online_peer` commands `create_live_room`, `join_live_room`, and `exit_live_room`
do write to the production QA room. They are **not** invoked by run_online.ps1.
Use them only with explicit authorization for QA_CratAble_20261002; remove its exact
returned ID after testing. Never run create_live_room twice without cleanup.

Interaction coverage includes Guest hand drops on a rotated board, rotation-handle input, locked-dice mouse input, replaying a private card and returning private cards to a shared deck. These are scripted input-handler tests, not manual mouse QA.

The Guest clicks the center of an empty, rotated placement zone to open the deck picker.
The zone caption faces the screen on both peers. Both click the same movement-locked deck
after a Guest selection, flip, and snapshot. The test checks their hand cards, the
remaining order, cover textures and a failed card lookup. `deck_selection.tscn`
also checks that a saved deck is immediately playable and the Guest picker survives
a field snapshot between mouse press and release. The same test opens a deck from
its context menu across a snapshot and checks Cancel returns input to the board (18/18).

Focused local scene: `res://tests/deck_top.tscn` expects `DECK_TOP_RESULT 22/22`.
It verifies the actual cover texture against the next draw, top/bottom returns,
shuffle, viewer reorder, empty piles, remote pile updates and stale image callbacks
in the tabletop and field creator. It does not write database rows.

`res://tests/deck_flip_help.tscn` expects `FLIP_HELP_RESULT 16/16`: deck context-menu flip, physical reversal, backs, snapshot restoration, repeated remote delivery, and Help navigation. The online suite also tests Guest flip, resync, and Host flip back.


## Interaction polish (2026-10-22)
- `editor_selection.tscn`: creator-only selection, copy, delete and nested transforms (20 checks).
- `interaction_polish.tscn`: Undo/Redo, branching history, alignment/Alt bypass, Shift axis lock, test-mode guard, dice geometry, remote tween cancellation, interactive help progress/reset (17 checks). Optional `-- output=<absolute.png>` renders the Help page with a non-headless engine.
- Creator history holds up to 50 snapshots in memory, clears when loading another field, and does not operate during play/test or text editing.
- Run scripts in an isolated QA project; online regression uses a unique ephemeral Realtime channel, not room-table writes.


## Creator integrity (2026-10-27)
- `creator_integrity.tscn`: 28 checks covering automatically assigned field IDs, legacy generated IDs, marquee copy hierarchy, nested rotated/scaled drop targets in editor/gameplay, hover-safe Redo, idle history, dirty exit, canceled save, atomic draft overwrite/recovery, Test Mode isolation and narrow tutorial layout.
- `run_online.ps1`: now 29 checks including nested drop replication and reconnect without duplicate components. Uses a unique Realtime test channel; no room-table writes.
- QA project should set `[cratable] recovery_enabled=false` to avoid startup recovery dialogs; the integrity test temporarily enables persistence only in the isolated QA user directory and cleans its recovery file.
- Copy `scripts/`, matching `scenes/`, and `tests/` into the isolated QA checkout before running. The Creator preview uses real generated IDs, not fixture IDs.

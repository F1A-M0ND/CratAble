# Regression tests

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

Expect `ONLINE_RESULT 22/22`. This starts two headless Godot processes, connects
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

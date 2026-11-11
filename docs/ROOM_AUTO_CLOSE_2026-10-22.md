# Empty room closure — awaiting production approval

Prepared: `supabase/room_presence.sql`, `supabase/verify_room_presence.sql`, `scripts/RoomSession.gd`.

- Token-authenticated heartbeat every 30 seconds while the online tabletop is open.
- Last explicit leave closes the room immediately. Leaving Host does not close a room with a live Guest.
- Server expires sessions after 120 seconds; a private SQL cleanup job runs every 30 seconds. With normal scheduler operation, crash/disconnect cleanup occurs about 120–150 seconds after the last heartbeat.
- Window close attempts leave, then exits within 2 seconds. Network failures use the server timeout.
- No automatic deletion of room history, cards, decks or fields.
- SQL deployment requires all legacy active rooms to be closed first. Older clients do not send this heartbeat and must restart on the updated version.
- The remaining Guest can keep the room alive after Host leaves. This does not transfer the Host role or implement new player admission to a hostless room.

Read-only inspection found these 8 active-status rooms (actual occupancy cannot be established from the old schema):

| Name | ID | Created (UTC) |
|---|---|---|
| Room_270 | 9a07ed39-79ad-4c27-83ad-d3db1b603e03 | 2026-10-02 06:38 |
| Room_378 | 90c275e2-d9a3-430b-b5b5-f01796118b46 | 2026-10-02 07:54 |
| Room_342 | 1dc17139-8161-4f4c-b7d4-5ceac42451d8 | 2026-10-03 12:52 |
| Room_44 | cccf312c-c694-4d3d-bb17-b86ae02f0765 | 2026-10-03 12:53 |
| Room_374 | 898f1e18-5966-4181-a7f0-eeceac132511 | 2026-10-22 14:12 |
| Room_569 | 98a10c3b-43f2-4cca-b529-b8c14116ec2e | 2026-10-22 14:15 |
| Room_493 | f11cb54c-d8fa-45ef-8f9f-46056abf0002 | 2026-10-22 14:23 |
| Room_356 | 0ac0b0ed-034a-45a1-bacc-082f6459511a | 2026-10-22 14:44 |

Client fixture `tests/room_session.tscn`: 11/11 passed against a fake service; no production writes. SQL tests are prepared but NOT executed. Deployment and enabling pg_cron are NOT completed. After approval, inspect schema/rooms again, close only confirmed unused room IDs, apply the reviewed SQL, run rollback-only SQL tests, check advisors and cron job results, and verify live lifecycle in an explicitly authorized QA fixture.

Cron references: https://supabase.com/docs/guides/cron/install and https://supabase.com/docs/guides/cron/quickstart .

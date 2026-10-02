# Applied and verified: 2026-10-02

Migration `secure_rooms` was applied to `oprwntnvhqxuhztuakdx` after live schema review
and the user's explicit authorization to close the 56 inactive legacy rooms.
All 56 rows were retained. SQL regression and live Godot room lifecycle tests passed.
See `docs/QA_FIXES_2026-10-02.md` for results and advisor review.

The following notes record the deployment preparation:

# Room security migration — pending live validation

The user approved `migrations/20261002_secure_rooms.sql` on 2026-10-02, conditional
on inspecting the live schema and ensuring no real rooms are active. Approval
does not mean the SQL has run. At handoff, no SQL-capable Supabase connection was confirmed.

Run `preflight.sql` read-only first. Check the ID type is UUID, nullable legacy
password, accepted status values, JSON assignment compatibility, pgcrypto location,
existing functions/views and table/column grants. Review any other definer functions
that expose rooms; revoking direct table grants does not revoke those functions.

The migration hashes historical passwords, clears plaintext, introduces session
tokens and random channel identifiers, and restricts client access to four RPCs.
It does not change cards/decks/fields. Old room clients are incompatible; deploy
the matching client and database changes in a maintenance window. The transaction
aborts if any non-QA waiting/playing room exists. Do not remove that guard casually.

After applying, run `verify_rooms.sql`: it checks anon direct-access denial, wrong
password rejection, occupied-room rejection, distinct session tokens, invalid leave
token rejection, guest reopening, and host closing. Its test row changes roll back.
Then verify the Godot room UI with the authorized QA room and clean it up.

Random channel identifiers act as shared room capabilities; this is not per-player
Realtime authorization or anti-cheat. Do not expose these identifiers in room lists
or logs. Players inside a room already share its tabletop state. Account identity,
rate limiting and stronger adversarial-client defenses are separate work.

Security-definer functions use explicit schema qualification, a fixed empty search
path, and explicit execution grants following the [Supabase function guidance](https://supabase.com/docs/guides/database/functions).

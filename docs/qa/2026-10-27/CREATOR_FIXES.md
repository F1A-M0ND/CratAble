# Creator integrity improvements — 2026-10-27

## Fixed
- New subfields had generated `@ColorRect...` names; component lookup treated every such name as the main board. This dropped the field itself from clipboard copies. Subfields now have unique persistent IDs and draggable signals; legacy component identifiers resolve normally. Reproduced with a real spawned field in the rendered preview, then added regression coverage.
- Drop targets only searched direct children. Shared placement now searches nested fields/zones using their inverse transforms, reparents cards to the destination surface, and clamps them within it. Copies preserve child hierarchy; copying a child alone preserves its parent field. Parent-relative placement replicates to both online clients.
- Save/snapshot reconstruction preserves scale and pivot, including smaller fields; queued-for-deletion objects are omitted.
- Hover no longer changes document pivots. History records after edit input rather than polling the entire board every 300 ms. Idle overlays stop redrawing unnecessarily.
- Field Creator protects Back, window close, and replacement by loaded local/online documents. Save cancellation clears a pending leave. Unsaved drafts are stored locally, written via a temporary file, offered for recovery, and cleared after save/discard. Test Mode mutations are restored instead of leaking into the authored document.

## UI
Restrained borders/shadows and wood grain; clearer Thai Creator controls and document status; shorter zone labels with wrapping; Home separates Play and Create and uses factual Thai copy. Practice layout stacks at narrow widths and uses a right-click flip menu consistent with gameplay.

## Verification
28 integrity checks; existing suites: selection 20, interaction polish 17, hand orientation 40, deck top 22, deck selection 13, deck flip/help 16, inspector 8. Online suite passed 29 checks, including transient disconnect/rejoin. Host and Guest snapshots both placed QANestedCard under QANestedZone at (0,0), rotation 0. These are automated handler/network checks plus rendered visual inspection, not exhaustive manual QA.

Creator preview: creator-improved.png. No production database schema/data migration was run. Changes are not pushed. Recovery stores the active Creator draft; it is not a multi-project version-history service. The larger library/import-export roadmap remains separate work.

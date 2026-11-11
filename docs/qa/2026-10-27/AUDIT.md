# Product quality audit — 2026-10-27

Scope: local source review, isolated Godot QA tests, current tabletop render, official design/accessibility references. No application fixes, production database writes or push. Online end-to-end was not rerun in this audit. This is a targeted audit, not proof of absence of other defects.

## Confirmed findings

1. P1: Hover invalidates Redo. Create zone, record, move it, record, undo, hover restored zone, allow history recording. Cursor changes from 1/3 states to 2/3 states and redo becomes unavailable. EditorHistory captures editor_pivot; DraggableControl hover changes pivot from (0,0) to size/2. Visual hover should not create document history. Reproduction calls the real hover handler and the same record method used by the timer.
2. P1: FieldCreator Back immediately changes scene without a dirty-document guard (FieldCreator.gd _on_back_pressed). Unlike CardEditor, it does not check unsaved changes. Protect Back/window close and add local recovery drafts. Source-confirmed missing protection; no real user work discarded in testing.
3. P2: TutorialPractice at available width 360 places the dice button's right edge at 420, exceeding its bounds by 60 pixels. reset_layout hardcodes minimum X=290 and width=130. Reproduced programmatically at component level; not a claim that the current desktop opens at this width by default. Use responsive stacked layout and test application window sizes/UI scaling.
4. Performance risk: snapshot recording measured 1.318 ms at 50 components, 7.149 ms at 200, 14.266 ms at 500 in a single local run. EditorSelection performs this every 0.3 seconds when idle, even without a document change, and requests redraw every frame. At a 60 fps target (16.7 ms frame budget), 500-object snapshot work alone is significant. These are CPU timings, not measured application frame rates. Prefer mutation-driven history and redraw; profile full scenarios at p95/p99 before claiming smoothness.

## Current regression results

interaction_polish 17/17; editor_selection 20/20; hand_orientation 40/40; inspector_image 8/8. Total 85/85. New adversarial cases still reveal the issues above. Screenshot rendered with Godot 4.6.1 compatibility on Intel UHD Graphics. ui_preview intentionally sets board position/scale, so its cropping is not used as evidence of a default framing bug.

## UI/UX observations and proposed direction

The tabletop shows configuration text such as Place/Up/Move/Max in play, and zone text can extend beyond its container in the preview. Collapse technical settings into Creator's inspector; play should show only useful names, counts and available actions. The wood texture has strong repeated grain; reduce contrast and make cards the visual focus. Buttons/panels share prominent borders and shadows, weakening hierarchy. Thai/English labels are mixed. Adopt shared semantic colors, spacing, type, focus and state styles.

Suggested structure: Home with Continue and recent projects; Library with search/filter/sort and stable thumbnails; Creator with broad canvas and contextual properties; Play with centered table, readable hand, participant/network status; Help with task-based practice using the same controls as actual play. These are proposed adaptations inspired by familiar large consumer products, not claims about their internal design systems.

Suggested tokens: background #0F1014, surface #1A1C23, elevated #242731, accent #FF8A3D, text #F5F5F7, secondary #ADB2BF; spacing 4/8/12/16/24/32; restrained 10–16 radius; body 16–18 with user scaling. Verify contrast in actual backgrounds. Reserve glass for overlays instead of every surface. Reduce Motion, keyboard focus/navigation and predictable menus matter as much as animation.

Delivery order: (1) protect work and fix history; (2) profile/reduce main-thread work and test network interruptions; (3) shared UI design system plus Home/Library/Creator/Play layouts; (4) accessible, accurate onboarding and recovery states; (5) asset packaging/import/export and starter templates. Keep free-form game rules.

Acceptance targets to validate, not measured results: interaction feedback within ~100 ms, typical gameplay p95 frame time <=16.7 ms on agreed minimum hardware, no unintentional data loss, reconnect without duplicate objects, usable layout at 1280x720/1366x768/1920x1080 and high DPI, keyboard-accessible primary workflows, cancelable animations and no stacked tweens.

References: https://m3.material.io/styles/motion/overview/how-it-works ; https://www.w3.org/WAI/WCAG21/Understanding/animation-from-interactions ; https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum

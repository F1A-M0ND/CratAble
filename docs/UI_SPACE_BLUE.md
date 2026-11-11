# CratAble — Sky / Indigo UI

Design direction approved by the owner on 2026-11-11: space imagery inspired by the supplied Astra page, bold italic display typography inspired by GeoGuessr, and **sky blue / indigo / white / black**, replacing the earlier orange palette.

## Visual system

- Near-black space background; sky `#73ceff`, indigo `#6677ef`, white `#f5f9ff`, dark glass `#121b30`.
- Barlow Black Italic for navigation and short English headings; Noto Sans Thai for readable Thai instructions. Fonts are bundled for offline/Web rendering, with their OFL licenses.
- Main navigation is at the top. Home offers Play, Create, and a direct path to the interactive guide.
- Original generated space/tabletop illustration: `assets/art/space-tabletop-blue.png`. Small chooser illustrations are code-drawn vectors in `ChooserArtwork.gd`.
- Home uses one eased, viewport-wide cursor camera for its transparent planet/card/dice layers and procedural background. Card planes rotate around X/Y with perspective-correct UV sampling; nearer objects move farther and subtly change apparent size. The lower planet rotates slowly, changes spherical viewing angle, and sits in front of three star depths. Other screens retain a static starfield. No video background or particle system.
- Home motion pauses when hidden/unfocused and respects the browser's reduced-motion preference when Home opens.
- The central canyon globe has its own slow precession and elliptical bob, a traveling light with a tapered trail around the existing ring, and localized waterfall shimmer. Hovering over the globe gently accelerates the light and strengthens the water glow. Terrain occludes the far side of the orbit; the beads already painted in the artwork remain part of the illustration.
- Headings and navigation stay fixed. Leaving the window eases the camera back to center; losing focus resets it and pauses animation. The illustration is layered artwork with projected perspective, not a freely navigable 3D model.
- Custom UI components mark `style_owned` so the shared theme does not overwrite their styles. Saved tabletop components remain excluded from recursive styling.

## Scope

Home, navigation, Local/Online choices, Creator choices, online room list controls, interactive guide, shared inputs/dialogs and editor/play accents. The wooden tabletop and user-created artwork retain their own colors. This changes presentation, not game rules or room/database permissions.

Reference URLs supplied by the owner:
- https://openai.com/index/gpt-6-astra/
- https://www.geoguessr.com/


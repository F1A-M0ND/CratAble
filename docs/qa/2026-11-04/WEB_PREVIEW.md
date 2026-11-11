# Web preview verification — 2026-11-04

## Verified

- Godot 4.6.1 release Web export completes with no script/export errors in final export.log.
- Chromium-based in-app browser opens http://127.0.0.1:8060/ and renders the real main menu.
- Thai text renders using bundled Noto Sans Thai (initial missing-glyph problem fixed).
- Real browser file chooser → PNG → Card Editor preview.
- Save in this browser → reload page → card thumbnail → reopen editor with the same image.
- Replacing the image with JPG and WebP via the browser chooser displays the new image.
- Invalid PNG bytes show an error dialog and preserve the previously displayed image.
- Field Creator → import image → WebP appears as a tabletop object.
- Native isolated test scene: BROWSER_IMAGES_RESULT 14/14 (three decoders, reload,
  bounded paths, byte/dimension limits, unsupported files, desktop editor initialization).
- Native isolated Creator regression: CREATOR_INTEGRITY_RESULT 28/28.
- Start-Web.cmd launches the server; localhost HTTP responds 200.

## Limits and observed issues

- Browser card-library requests to Supabase returned Failed to fetch in this test
  environment. Local import/save/reopen succeeded independently. Cloud CORS/network
  diagnosis and end-to-end online gameplay remain separate work; no production writes
  or migrations were performed.
- Some decorative symbols in the existing Creator UI still lack glyphs in Web;
  Thai labels are readable. Custom menu emoji were replaced with 01/02/03 for Web.
- No two-machine online test, cross-browser matrix, browser quota-exhaustion test,
  immediate tab-close durability test, or deck/field portable export test is claimed.
- The editor's browser card list is not yet a unified local library for Deck Builder.
- Native tests ran in a separate project/user-data directory. Browser QA created one
  local card named Q and a disposable field draft in this preview origin only.
- Build output and downloaded templates are ignored. Existing unrelated working-tree
  changes were retained. Nothing was pushed.

Screenshots: web-card-import.jpg, web-field.jpg.
Detailed usage and boundaries: ../../WEB_PREVIEW.md.

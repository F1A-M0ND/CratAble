# CratAble Web preview

Local browser preview built with Godot 4.6.1, Compatibility renderer, single-threaded WebAssembly.

## Open on this computer

1. Double-click `Start-Web.cmd` in the project folder (keep its terminal open).
2. Open **http://127.0.0.1:8060/** in a WebGL 2 capable desktop browser.
3. Choose **CUSTOM → CARD EDITOR → Create New Card → Import picture**.
4. Choose PNG, JPG/JPEG or WebP (up to 12 MiB, up to 4096 pixels per side).
5. **Save Card → Save in this browser**. Back returns to the card list. Reloading
   the page preserves saved local cards and their copied images on the same origin/browser.
6. Stop the preview with Ctrl+C in its terminal.

To check the live database without editing it, open **CUSTOM → CARD EDITOR**.
The card list shows separate totals for online cards and cards saved in this browser.
If the online request fails, use **ลองอีกครั้ง** to reload it. In **DECK BUILDER**,
use **Open → Open Online (Database)**. In **FIELD CREATOR**, use **เปิดสนาม → Online**.

The launcher discovers the installed Codex Python runtime. With another Python 3 installation:

```powershell
./tools/start_web.ps1 -Python 'C:/path/to/python.exe'
```

Do not open `index.html` through file://. Serve the entire `build/web` folder over HTTP.
The server listens only on 127.0.0.1 and exposes only compiled web assets, not source files.

## Rebuild

```powershell
python tools/fetch_web_templates.py
./tools/build_web.ps1 -Engine 'C:/path/to/Godot_v4.6.1-stable_win64_console.exe'
```

The fetch helper uses Windows curl with TLS verification to retrieve only the two
Web ZIP members from the official 4.6.1 archive, verifying their ZIP CRCs. Templates
and generated builds are ignored by Git. Alternatively extract the official
`web_nothreads_debug.zip` and `web_nothreads_release.zip` to `.web-tools/`.
Rebuild imports assets, exports the preset, and rejects script/export errors.

## Scope and remaining work

- This is a local Web preview, not a public deployment or a new account system.
- Local image import is also connected to Field Creator's image-object picker.
- Browser cards/images use user:// backed by the browser's persistent storage.
  Clearing site data, private browsing, storage eviction, or switching origin/browser
  can remove or hide them. This is not cloud backup or a portable card package.
- Desktop file pickers retain their existing behavior.
- Deck/field JSON import-export still uses the original Godot dialogs and requires a
  separate browser file workflow. Do not treat this preview as complete web parity.
- Verified in the browser against Supabase: card metadata and images, opening a saved deck,
  and opening a saved field. Browser Fetch decodes compressed responses, so Godot's
  HTTPRequest decompression is disabled on Web for both JSON and textures.
  Online writes, account ownership, private Storage, and two-browser room play
  are outside this read-only check.
- Font: Noto Sans Thai from Google Fonts, bundled under SIL OFL; see assets/fonts/OFL.txt.

## References

- https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_web.html
- https://docs.godotengine.org/en/4.6/classes/class_filedialog.html
- https://docs.godotengine.org/en/4.6/classes/class_javascriptbridge.html
- https://github.com/google/fonts/tree/main/ofl/notosansthai

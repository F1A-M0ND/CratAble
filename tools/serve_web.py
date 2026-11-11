"""Local-only preview; serves build/web, never the source checkout."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--port', type=int, default=8060)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1] / 'build' / 'web'
if not (root / 'index.html').exists():
    raise SystemExit('Build first: tools/build_web.ps1')

class Handler(SimpleHTTPRequestHandler):
    extensions_map = {**SimpleHTTPRequestHandler.extensions_map, '.wasm': 'application/wasm', '.pck': 'application/octet-stream'}
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

server = ThreadingHTTPServer(('127.0.0.1', args.port), partial(Handler, directory=str(root)))
print(f'CratAble: http://127.0.0.1:{args.port}/ (Ctrl+C to stop)', flush=True)
server.serve_forever()

"""Fetch only the Web ZIP members of the official Godot 4.6.1 TPZ over HTTPS.

Range reads avoid downloading unrelated platform templates. ZipFile verifies
each extracted member's CRC; no archive paths are used as output paths.
"""
import io
import pathlib
import zipfile
import subprocess
import re

URL = 'https://github.com/godotengine/godot-builds/releases/download/4.6.1-stable/Godot_v4.6.1-stable_export_templates.tpz'

class RemoteZip(io.RawIOBase):
    def __init__(self):
        # Windows curl uses the OS TLS stack; do not disable certificate checks.
        response = subprocess.check_output(['curl.exe', '-fsSLI', '--max-time', '60', '-w', '\n%{url_effective}', URL]).decode()
        self.url = response.strip().splitlines()[-1]
        self.length = int(re.findall(r'(?im)^content-length:\s*(\d+)', response)[-1])
        self.pos = 0
    def seekable(self): return True
    def tell(self): return self.pos
    def seek(self, offset, whence=0):
        self.pos = offset + (self.pos if whence == 1 else self.length if whence == 2 else 0)
        return self.pos
    def read(self, size=-1):
        size = min(self.length-self.pos, size if size >= 0 else self.length)
        if size <= 0: return b''
        data = subprocess.check_output(['curl.exe', '-fsSL', '--max-time', '180', '--range', f'{self.pos}-{self.pos+size-1}', self.url])
        if len(data) != size: raise RuntimeError('Server returned an incorrect range')
        self.pos += len(data)
        return data

out = pathlib.Path(__file__).resolve().parents[1] / '.web-tools'
out.mkdir(exist_ok=True)
with zipfile.ZipFile(RemoteZip()) as archive:
    for name in ('web_nothreads_release.zip', 'web_nothreads_debug.zip'):
        entry = next(n for n in archive.namelist() if n.endswith('/' + name))
        data = archive.read(entry)
        (out / name).write_bytes(data)
        print(f'{name}: {len(data)} bytes (CRC verified)', flush=True)

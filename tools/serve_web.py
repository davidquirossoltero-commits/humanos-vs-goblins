#!/usr/bin/env python3
"""Sirve la exportación web con el tipo MIME de .wasm."""

import http.server
import os
import socketserver
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 5199
ROOT = sys.argv[2] if len(sys.argv) > 2 else "build/web"


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = http.server.SimpleHTTPRequestHandler.extensions_map.copy()
    extensions_map.update({
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
    })

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


os.chdir(ROOT)
with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
    print(f"Sirviendo {os.getcwd()} en http://127.0.0.1:{PORT}")
    httpd.serve_forever()

#!/usr/bin/env python3
"""A tiny fake API for Module 0.4, so 'the server returns 500' happens every time you run it.

  python3 stub_api.py            serves on http://127.0.0.1:8000   (Ctrl+C to stop)

  /health  -> 200 {"status":"ok"}
  /flaky   -> 500 {"error":"boom"}
  /slow    -> waits 5 seconds, then 200   (to trigger a timeout)
  anything else -> 404
"""
import json
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class Handler(BaseHTTPRequestHandler):
    def _send(self, status, body):
        data = json.dumps(body, separators=(",", ":")).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/health":
            self._send(200, {"status": "ok"})
        elif self.path == "/flaky":
            self._send(500, {"error": "boom"})
        elif self.path == "/slow":
            time.sleep(5)
            self._send(200, {"status": "ok"})
        else:
            self._send(404, {"error": "not found"})

    def log_message(self, fmt, *args):  # keep the terminal quiet
        pass


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"stub API on http://127.0.0.1:{port}  (Ctrl+C to stop)")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass

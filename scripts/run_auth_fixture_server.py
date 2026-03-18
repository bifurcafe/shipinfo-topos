#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse
import json

PORT = 18090
TOKEN = "fixture_test_key"


def envelope(status="ok", data=None, errors=None):
    return {
        "status": status,
        "request_id": "fixture-req",
        "as_of": "2026-02-26T00:00:00Z",
        "freshness_seconds": 0,
        "cost_units": 0.0,
        "policy": {
            "attribution_required": True,
            "attribution_text": "Data by ShipInfo.net",
            "usage_tier": "fixture",
        },
        "confidence": 1.0,
        "quality_flags": [],
        "data": data or {},
        "errors": errors or [],
    }


class H(BaseHTTPRequestHandler):
    def _write(self, code, payload):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _is_auth_ok(self):
        auth = self.headers.get("Authorization", "")
        return auth == f"Bearer {TOKEN}"

    def do_GET(self):
        path = urlparse(self.path).path

        if path in ("/.well-known/agent-manifest.json", "/.well-known/openapi.json", "/.well-known/schemas/index.json", "/v1/ping", "/v1/capabilities", "/v1/policy", "/v1/quality", "/v1/billing/x402/requirements"):
            self._write(200, envelope("ok", {"fixture": True, "path": path}, []))
            return

        protected = {
            "/v1/vessels/lookup",
            "/v1/ports/search",
            "/v1/sts/events",
            "/v1/metrics/route_stress_index",
        }
        if path in protected:
            if not self._is_auth_ok():
                self._write(401, envelope("error", {}, ["auth_required"]))
                return
            self._write(200, envelope("ok", {"fixture": True, "path": path}, []))
            return

        self._write(404, envelope("error", {}, ["not_found"]))

    def log_message(self, fmt, *args):
        return


if __name__ == "__main__":
    HTTPServer(("127.0.0.1", PORT), H).serve_forever()

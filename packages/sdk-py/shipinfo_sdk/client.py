from __future__ import annotations

import json
import time
from typing import Any, Dict, List, Optional

import httpx

from .errors import ShipInfoDecodeError, ShipInfoHttpError

RETRYABLE_STATUS = {429, 500, 502, 503, 504}


class ShipInfoClient:
    def __init__(
        self,
        base_url: str = "https://shipinfo.net/topos/api",
        api_key: Optional[str] = None,
        agent_headers: Optional[Dict[str, str]] = None,
        timeout: float = 20.0,
        max_retries: int = 2,
        retry_base_seconds: float = 0.5,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.agent_headers = agent_headers or {}
        self.timeout = timeout
        self.max_retries = max_retries
        self.retry_base_seconds = retry_base_seconds

    def _headers(self) -> Dict[str, str]:
        h: Dict[str, str] = {"Accept": "application/json"}
        if self.api_key:
            h["Authorization"] = f"Bearer {self.api_key}"
        if self.agent_headers.get("name"):
            h["X-Agent-Name"] = self.agent_headers["name"]
        if self.agent_headers.get("vendor"):
            h["X-Agent-Vendor"] = self.agent_headers["vendor"]
        if self.agent_headers.get("contact"):
            h["X-Agent-Contact"] = self.agent_headers["contact"]
        if self.agent_headers.get("session"):
            h["X-Agent-Session"] = self.agent_headers["session"]
        return h

    def _parse_payment_required(self, header_value: Optional[str]) -> Optional[Any]:
        if not header_value:
            return None
        try:
            return json.loads(header_value)
        except ValueError:
            return header_value

    def _request_json(
        self,
        method: str,
        path: str,
        params: Optional[Dict[str, Any]] = None,
        json_body: Optional[Dict[str, Any]] = None,
        extra_headers: Optional[Dict[str, str]] = None,
    ) -> Dict[str, Any]:
        params = params or {}
        headers = self._headers()
        if extra_headers:
            headers.update(extra_headers)
        attempt = 0
        while True:
            with httpx.Client(timeout=self.timeout) as client:
                response = client.request(
                    method.upper(),
                    f"{self.base_url}{path}",
                    params=params,
                    json=json_body,
                    headers=headers,
                )
            if response.status_code < 400:
                try:
                    payload = response.json()
                except ValueError as exc:
                    raise ShipInfoDecodeError("invalid json response") from exc
                if not isinstance(payload, dict):
                    raise ShipInfoDecodeError("json payload is not an object")
                return payload

            retryable = response.status_code in RETRYABLE_STATUS
            if retryable and attempt < self.max_retries:
                attempt += 1
                time.sleep(self.retry_base_seconds * attempt)
                continue

            response_headers = {k.lower(): v for k, v in response.headers.items()}
            payment_required = self._parse_payment_required(response_headers.get("payment-required"))
            raise ShipInfoHttpError(
                response.status_code,
                response.text,
                retryable,
                response_headers=response_headers,
                payment_required=payment_required,
            )

    def get_paginated(
        self,
        path: str,
        params: Optional[Dict[str, Any]] = None,
        limit_pages: int = 10,
        cursor_field: str = "next_cursor",
        items_field: Optional[str] = None,
    ) -> Dict[str, Any]:
        params = dict(params or {})
        pages: List[Dict[str, Any]] = []
        all_items: List[Any] = []

        for _ in range(max(1, limit_pages)):
            payload = self._request_json("GET", path, params=params)
            pages.append(payload)

            data = payload.get("data") if isinstance(payload, dict) else None
            if isinstance(data, dict):
                if items_field and isinstance(data.get(items_field), list):
                    all_items.extend(data[items_field])
                cursor = data.get(cursor_field)
                if not cursor:
                    break
                params["cursor"] = cursor
            else:
                break

        return {"pages": pages, "all_items": all_items}

    def capabilities(self) -> Dict[str, Any]:
        return self._request_json("GET", "/v1/capabilities")

    def policy(self) -> Dict[str, Any]:
        return self._request_json("GET", "/v1/policy")

    def quality(self) -> Dict[str, Any]:
        return self._request_json("GET", "/v1/quality")

    def billing_pricing(self) -> Dict[str, Any]:
        return self._request_json("GET", "/v1/billing/pricing")

    def billing_x402_requirements(self, resource: str = "/topos/api/v1/vessels/lookup") -> Dict[str, Any]:
        return self._request_json("GET", "/v1/billing/x402/requirements", params={"resource": resource})

    def billing_x402_verify(
        self,
        resource: str,
        payment: Dict[str, Any],
        payment_signature: Optional[str] = None,
    ) -> Dict[str, Any]:
        headers: Dict[str, str] = {}
        if payment_signature:
            headers["PAYMENT-SIGNATURE"] = payment_signature
        return self._request_json(
            "POST",
            "/v1/billing/x402/verify",
            json_body={"resource": resource, "payment": payment},
            extra_headers=headers,
        )

    def vessel_lookup(self, vessel_id: str) -> Dict[str, Any]:
        return self._request_json("GET", "/v1/vessels/lookup", params={"id": vessel_id})

    def port_congestion(self, port_id: int, range: Optional[str] = None, vessel_type: Optional[str] = None) -> Dict[str, Any]:
        params: Dict[str, Any] = {}
        if range:
            params["range"] = range
        if vessel_type:
            params["vessel_type"] = vessel_type
        return self._request_json("GET", f"/v1/ports/{port_id}/congestion", params=params)

    def sts_events(self, **kwargs: Any) -> Dict[str, Any]:
        return self._request_json("GET", "/v1/sts/events", params=kwargs)

    def route_stress_index(self, zone_key: Optional[str] = None, range: Optional[str] = None) -> Dict[str, Any]:
        params: Dict[str, Any] = {}
        if zone_key:
            params["zone_key"] = zone_key
        if range:
            params["range"] = range
        return self._request_json("GET", "/v1/metrics/route_stress_index", params=params)

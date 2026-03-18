from typing import Any, Dict, Optional


class ShipInfoError(Exception):
    pass


class ShipInfoHttpError(ShipInfoError):
    def __init__(
        self,
        status_code: int,
        body_text: str,
        retryable: bool,
        response_headers: Optional[Dict[str, str]] = None,
        payment_required: Optional[Any] = None,
    ) -> None:
        self.status_code = status_code
        self.body_text = body_text
        self.retryable = retryable
        self.response_headers = response_headers or {}
        self.payment_required = payment_required
        super().__init__(f"HTTP {status_code}: {body_text}")


class ShipInfoDecodeError(ShipInfoError):
    pass

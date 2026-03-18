const RETRYABLE_STATUS = new Set([429, 500, 502, 503, 504]);

export class ShipInfoClient {
  constructor(opts = {}) {
    this.baseUrl = (opts.baseUrl || "https://shipinfo.net/topos/api").replace(/\/$/, "");
    this.apiKey = opts.apiKey || null;
    this.agentHeaders = opts.agentHeaders || {};
    this.timeoutMs = Number(opts.timeoutMs || 20000);
    this.maxRetries = Number(opts.maxRetries || 2);
    this.retryBaseMs = Number(opts.retryBaseMs || 500);
  }

  headers(extra = {}) {
    const out = { Accept: "application/json", ...extra };
    if (this.apiKey) out.Authorization = `Bearer ${this.apiKey}`;
    if (this.agentHeaders.name) out["X-Agent-Name"] = this.agentHeaders.name;
    if (this.agentHeaders.vendor) out["X-Agent-Vendor"] = this.agentHeaders.vendor;
    if (this.agentHeaders.contact) out["X-Agent-Contact"] = this.agentHeaders.contact;
    if (this.agentHeaders.session) out["X-Agent-Session"] = this.agentHeaders.session;
    return out;
  }

  sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  parsePaymentRequiredHeader(value) {
    if (!value) return null;
    try {
      return JSON.parse(value);
    } catch (_err) {
      return value;
    }
  }

  async request(method, path, { query = {}, body = null, extraHeaders = {} } = {}) {
    const u = new URL(this.baseUrl + path);
    Object.entries(query).forEach(([k, v]) => {
      if (v !== undefined && v !== null && `${v}` !== "") u.searchParams.set(k, `${v}`);
    });

    let attempt = 0;
    while (true) {
      const ctrl = new AbortController();
      const timer = setTimeout(() => ctrl.abort(), this.timeoutMs);
      try {
        const headers = this.headers(extraHeaders);
        const init = {
          method: method.toUpperCase(),
          headers,
          signal: ctrl.signal,
        };
        if (body !== null && body !== undefined) {
          init.body = JSON.stringify(body);
          if (!headers["Content-Type"]) headers["Content-Type"] = "application/json";
        }
        const res = await fetch(u.toString(), {
          ...init,
        });

        const body = await res.json().catch(() => ({ status: "error", errors: ["invalid_json"] }));
        if (res.ok) return body;

        const retryable = RETRYABLE_STATUS.has(res.status);
        if (retryable && attempt < this.maxRetries) {
          attempt += 1;
          await this.sleep(this.retryBaseMs * attempt);
          continue;
        }

        const err = new Error(`HTTP ${res.status}`);
        err.status = res.status;
        err.body = body;
        err.retryable = retryable;
        err.requestId = res.headers.get("x-request-id") || "";
        err.paymentRequired = this.parsePaymentRequiredHeader(res.headers.get("payment-required"));
        err.paymentSignature = res.headers.get("payment-signature") || "";
        throw err;
      } finally {
        clearTimeout(timer);
      }
    }
  }

  async get(path, query = {}) {
    return this.request("GET", path, { query });
  }

  async post(path, body = {}, opts = {}) {
    return this.request("POST", path, { body, extraHeaders: opts.extraHeaders || {} });
  }

  async getPaginated(path, query = {}, opts = {}) {
    const limitPages = Number(opts.limitPages || 10);
    const cursorField = opts.cursorField || "next_cursor";
    const itemsPath = opts.itemsPath || null;

    const pages = [];
    const allItems = [];
    let cursor = query.cursor || null;
    for (let i = 0; i < limitPages; i += 1) {
      const payload = await this.get(path, { ...query, cursor });
      pages.push(payload);

      if (itemsPath && payload && payload.data && Array.isArray(payload.data[itemsPath])) {
        allItems.push(...payload.data[itemsPath]);
      }

      const nextCursor = payload && payload.data ? payload.data[cursorField] : null;
      if (!nextCursor) break;
      cursor = nextCursor;
    }

    return { pages, allItems };
  }

  capabilities() { return this.get("/v1/capabilities"); }
  policy() { return this.get("/v1/policy"); }
  quality() { return this.get("/v1/quality"); }
  billingPricing() { return this.get("/v1/billing/pricing"); }
  billingX402Requirements(params = {}) { return this.get("/v1/billing/x402/requirements", params); }
  billingX402Verify({ resource, payment, paymentSignature } = {}) {
    const extraHeaders = {};
    if (paymentSignature) extraHeaders["PAYMENT-SIGNATURE"] = paymentSignature;
    return this.post("/v1/billing/x402/verify", { resource, payment }, { extraHeaders });
  }

  vesselLookup(params) { return this.get("/v1/vessels/lookup", params); }

  portCongestion(params) {
    const { port_id, ...rest } = params;
    return this.get(`/v1/ports/${port_id}/congestion`, rest);
  }

  stsEvents(params = {}) { return this.get("/v1/sts/events", params); }

  routeStressIndex(params = {}) { return this.get("/v1/metrics/route_stress_index", params); }
}

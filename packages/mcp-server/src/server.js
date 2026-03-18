import http from "node:http";

const API_BASE = (process.env.SHIPINFO_API_BASE || "https://shipinfo.net/topos/api").replace(/\/$/, "");
const API_KEY = process.env.SHIPINFO_API_KEY || "";
const PORT = Number(process.env.MCP_PORT || 8088);

const TOOLS = {
  vessel_lookup: {
    path: "/v1/vessels/lookup",
    validate: (a) => typeof a.id === "string" && a.id.trim() !== "",
    map: (a) => ({ id: a.id.trim() }),
  },
  port_congestion: {
    path: "/v1/ports/{port_id}/congestion",
    validate: (a) => Number.isInteger(Number(a.port_id)) && Number(a.port_id) > 0,
    map: (a) => ({ range: a.range, vessel_type: a.vessel_type }),
  },
  sts_events: {
    path: "/v1/sts/events",
    validate: () => true,
    map: (a) => ({ from: a.from, to: a.to, zone: a.zone, cursor: a.cursor, limit: a.limit }),
  },
  route_stress_index: {
    path: "/v1/metrics/route_stress_index",
    validate: () => true,
    map: (a) => ({ zone_key: a.zone_key, range: a.range }),
  },
};

function sendJson(res, code, body) {
  res.writeHead(code, { "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(body));
}

function errPayload(code, message, retryable = false, details = null, requestId = "") {
  return {
    status: "error",
    code,
    message,
    retryable,
    request_id: requestId || "",
    details,
  };
}

async function invokeTool(tool, args, reqHeaders) {
  const cfg = TOOLS[tool];
  if (!cfg) {
    return { code: 404, body: errPayload("unknown_tool", `Unknown tool: ${tool}`, false) };
  }

  const safeArgs = args && typeof args === "object" ? args : {};
  if (!cfg.validate(safeArgs)) {
    return { code: 422, body: errPayload("invalid_args", `Invalid args for tool: ${tool}`, false) };
  }

  let path = cfg.path;
  if (path.includes("{port_id}")) {
    path = path.replace("{port_id}", String(Number(safeArgs.port_id)));
  }

  const u = new URL(API_BASE + path);
  const q = cfg.map(safeArgs);
  Object.entries(q).forEach(([k, v]) => {
    if (v !== undefined && v !== null && `${v}` !== "") u.searchParams.set(k, `${v}`);
  });

  const headers = { Accept: "application/json" };
  if (API_KEY) headers.Authorization = `Bearer ${API_KEY}`;
  ["x-agent-name", "x-agent-vendor", "x-agent-session", "x-agent-contact"].forEach((k) => {
    if (reqHeaders[k]) headers[k] = String(reqHeaders[k]);
  });

  try {
    const r = await fetch(u.toString(), { headers });
    const upstreamRequestId = r.headers.get("x-request-id") || "";
    const body = await r.json().catch(() => errPayload("invalid_json", "Upstream returned invalid json", true, null, upstreamRequestId));

    if (!r.ok) {
      const retryable = [429, 500, 502, 503, 504].includes(r.status);
      const details = typeof body === "object" ? body : { raw: String(body) };
      return {
        code: r.status,
        body: errPayload("upstream_error", `Upstream HTTP ${r.status}`, retryable, details, upstreamRequestId),
      };
    }

    if (body && typeof body === "object" && !body.request_id && upstreamRequestId) {
      body.request_id = upstreamRequestId;
    }

    return { code: r.status, body };
  } catch (e) {
    return {
      code: 502,
      body: errPayload("upstream_unreachable", e instanceof Error ? e.message : "upstream unreachable", true),
    };
  }
}

const server = http.createServer(async (req, res) => {
  if (!req.url) return sendJson(res, 400, errPayload("bad_request", "Missing URL", false));
  if (req.method === "GET" && req.url === "/tools") {
    return sendJson(res, 200, { status: "ok", tools: Object.keys(TOOLS) });
  }

  if (req.method === "POST" && req.url === "/invoke") {
    let raw = "";
    req.on("data", (c) => {
      raw += c.toString("utf8");
      if (raw.length > 2 * 1024 * 1024) req.destroy();
    });
    req.on("end", async () => {
      let payload;
      try {
        payload = raw ? JSON.parse(raw) : {};
      } catch (_e) {
        return sendJson(res, 400, errPayload("invalid_json", "Request JSON is invalid", false));
      }

      const tool = payload && typeof payload.tool === "string" ? payload.tool : "";
      const args = payload && typeof payload.args === "object" && payload.args !== null ? payload.args : {};
      if (!tool) {
        return sendJson(res, 422, errPayload("missing_tool", "Field 'tool' is required", false));
      }

      const out = await invokeTool(tool, args, req.headers);
      return sendJson(res, out.code, out.body);
    });
    return;
  }

  return sendJson(res, 404, errPayload("not_found", "Route not found", false));
});

server.listen(PORT, () => {
  process.stdout.write(`shipinfo-mcp-server listening on :${PORT}\n`);
});

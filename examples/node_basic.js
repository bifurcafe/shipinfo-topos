import { ShipInfoClient } from "../packages/sdk-js/src/index.js";

async function main() {
  const c = new ShipInfoClient({ baseUrl: process.env.SHIPINFO_BASE_URL || "http://127.0.0.1/topos/api" });
  const out = await c.capabilities();
  console.log(out.status || "unknown");
}

main().catch((e) => {
  console.error(e?.message || e);
  process.exit(1);
});

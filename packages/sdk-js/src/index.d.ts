export type AgentHeaders = {
  name?: string;
  vendor?: string;
  contact?: string;
  session?: string;
};

export type ShipInfoClientOptions = {
  baseUrl?: string;
  apiKey?: string | null;
  agentHeaders?: AgentHeaders;
  timeoutMs?: number;
  maxRetries?: number;
  retryBaseMs?: number;
};

export declare class ShipInfoClient {
  constructor(opts?: ShipInfoClientOptions);
  request(method: string, path: string, opts?: { query?: Record<string, unknown>; body?: Record<string, unknown> | null; extraHeaders?: Record<string, string>; }): Promise<any>;
  get(path: string, query?: Record<string, unknown>): Promise<any>;
  post(path: string, body?: Record<string, unknown>, opts?: { extraHeaders?: Record<string, string>; }): Promise<any>;
  getPaginated(path: string, query?: Record<string, unknown>, opts?: { limitPages?: number; cursorField?: string; itemsPath?: string | null; }): Promise<{ pages: any[]; allItems: any[]; }>;
  capabilities(): Promise<any>;
  policy(): Promise<any>;
  quality(): Promise<any>;
  billingPricing(): Promise<any>;
  billingX402Requirements(params?: { resource?: string }): Promise<any>;
  billingX402Verify(params: { resource: string; payment: Record<string, unknown>; paymentSignature?: string }): Promise<any>;
  vesselLookup(params: { id: string }): Promise<any>;
  portCongestion(params: { port_id: number; range?: string; vessel_type?: string }): Promise<any>;
  stsEvents(params?: Record<string, unknown>): Promise<any>;
  routeStressIndex(params?: Record<string, unknown>): Promise<any>;
}

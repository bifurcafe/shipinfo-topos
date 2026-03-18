#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-https://shipinfo.net/topos/api}"
REQUEST_RESOURCE="${REQUEST_RESOURCE:-/topos/api/v1/vessels/lookup}"
EXPECTED_VERIFY_PATH="${EXPECTED_VERIFY_PATH:-/topos/api/v1/billing/x402/verify}"
EXPECTED_REQUIREMENTS_PATH="${EXPECTED_REQUIREMENTS_PATH:-/topos/api/v1/billing/x402/requirements}"
EXPECTED_PRICING_PATH="${EXPECTED_PRICING_PATH:-/topos/api/v1/billing/pricing}"
if [[ "$REQUEST_RESOURCE" != /topos/api/v1/* ]]; then
  echo "[fail] REQUEST_RESOURCE invalid_namespace_scope: $REQUEST_RESOURCE"
  exit 78
fi
if [[ "$REQUEST_RESOURCE" == *"?"* || "$REQUEST_RESOURCE" == *"#"* ]]; then
  echo "[fail] REQUEST_RESOURCE must_not_include_query_or_fragment: $REQUEST_RESOURCE"
  exit 79
fi
if [[ "$REQUEST_RESOURCE" =~ [[:space:]] ]]; then
  echo "[fail] REQUEST_RESOURCE must_not_include_whitespace: $REQUEST_RESOURCE"
  exit 80
fi
CURL_OPTS=( -sS -L )
[[ "$BASE_URL" == https://127.0.0.1* || "$BASE_URL" == https://localhost* ]] && CURL_OPTS+=( -k )

tmp_headers="$(mktemp)"
tmp_body="$(mktemp)"
policy_mode_file="$(mktemp)"
requirements_mode_file="$(mktemp)"
requirements_request_headers_file="$(mktemp)"
requirements_request_headers_ordered_file="$(mktemp)"
requirements_accepts0_file="$(mktemp)"
requirements_fee_bps_file="$(mktemp)"
requirements_amount_statement_file="$(mktemp)"
payment_required_file="$(mktemp)"
cleanup() {
  rm -f "$tmp_headers" "$tmp_body" "$policy_mode_file" "$requirements_mode_file" "$requirements_request_headers_file" "$requirements_request_headers_ordered_file" "$requirements_accepts0_file" "$requirements_fee_bps_file" "$requirements_amount_statement_file" "$payment_required_file"
}
trap cleanup EXIT

echo "[x402] requirements"
code="$(curl "${CURL_OPTS[@]}" -o "$tmp_body" -w '%{http_code}' "$BASE_URL/v1/billing/x402/requirements?resource=$REQUEST_RESOURCE")"
[[ "$code" == "200" ]] || { echo "[fail] requirements http=$code"; cat "$tmp_body"; exit 1; }
php -r '
$j=json_decode(file_get_contents($argv[1]), true);
if(!is_array($j) || !isset($j["status"]) || !isset($j["data"]["protocol"])) { fwrite(STDERR, "invalid requirements envelope\n"); exit(2); }
if((string)$j["data"]["protocol"] !== "x402") { fwrite(STDERR, "protocol!=x402\n"); exit(3); }
$requirementsMode = (string)($j["data"]["mode"] ?? "");
if($requirementsMode === "") { fwrite(STDERR, "requirements mode missing\n"); exit(4); }
file_put_contents($argv[2], $requirementsMode);
$challenge = (string)($j["data"]["headers"]["challenge"] ?? "");
if($challenge === "") { fwrite(STDERR, "requirements headers.challenge missing\n"); exit(5); }
if(trim($challenge) !== $challenge) { fwrite(STDERR, "requirements headers.challenge not_trimmed\n"); exit(61); }
if(strtoupper($challenge) !== $challenge) { fwrite(STDERR, "requirements headers.challenge not_uppercase\n"); exit(62); }
if($challenge !== "PAYMENT-REQUIRED") { fwrite(STDERR, "requirements headers.challenge invalid_value\n"); exit(6); }
$requestPayment = $j["data"]["headers"]["request_payment"] ?? null;
if(!is_array($requestPayment) || count($requestPayment) < 1) { fwrite(STDERR, "requirements headers.request_payment missing_or_empty\n"); exit(7); }
$requestPaymentOrdered = array_map("strval", $requestPayment);
foreach($requestPaymentOrdered as $headerName){
  if(trim($headerName) !== $headerName) { fwrite(STDERR, "requirements headers.request_payment not_trimmed\n"); exit(65); }
  if($headerName === "") { fwrite(STDERR, "requirements headers.request_payment has_empty_value\n"); exit(68); }
  if(preg_match("/^[A-Za-z0-9-]+$/", $headerName) !== 1) { fwrite(STDERR, "requirements headers.request_payment invalid_token\n"); exit(70); }
  if(strcasecmp($headerName, "X-PAYMENT") === 0 && $headerName !== "X-PAYMENT") { fwrite(STDERR, "requirements headers.request_payment invalid_casing_X-PAYMENT\n"); exit(72); }
  if(strcasecmp($headerName, "X402-Payment") === 0 && $headerName !== "X402-Payment") { fwrite(STDERR, "requirements headers.request_payment invalid_casing_X402-Payment\n"); exit(73); }
}
if(count(array_unique($requestPaymentOrdered)) !== count($requestPaymentOrdered)) { fwrite(STDERR, "requirements headers.request_payment has_duplicates\n"); exit(67); }
$requestPaymentSortedCheck = $requestPaymentOrdered;
sort($requestPaymentSortedCheck, SORT_STRING);
if($requestPaymentOrdered !== $requestPaymentSortedCheck) { fwrite(STDERR, "requirements headers.request_payment not_sorted\n"); exit(76); }
file_put_contents($argv[5], json_encode($requestPaymentOrdered));
$requestPaymentUnique = array_values(array_unique(array_map("strval", $requestPayment)));
$requestPaymentSorted = $requestPaymentUnique;
sort($requestPaymentSorted, SORT_STRING);
file_put_contents($argv[3], json_encode($requestPaymentSorted));
$requirementsAccepts = $j["data"]["accepts"] ?? null;
if(!is_array($requirementsAccepts) || count($requirementsAccepts) < 1) { fwrite(STDERR, "requirements accepts missing_or_empty\n"); exit(12); }
$r0 = is_array($requirementsAccepts[0] ?? null) ? $requirementsAccepts[0] : [];
$r0Payload = [
  "network" => (string)($r0["network"] ?? ""),
  "asset" => (string)($r0["asset"] ?? ""),
  "max_amount" => (string)($r0["max_amount"] ?? ""),
  "pay_to" => (string)($r0["pay_to"] ?? ""),
];
if($r0Payload["network"] === "" || $r0Payload["asset"] === "" || $r0Payload["max_amount"] === "" || $r0Payload["pay_to"] === "") {
  fwrite(STDERR, "requirements accepts[0] fields missing\n"); exit(13);
}
if(trim($r0Payload["network"]) !== $r0Payload["network"]) { fwrite(STDERR, "requirements accepts[0].network not_trimmed\n"); exit(87); }
if(trim($r0Payload["asset"]) !== $r0Payload["asset"]) { fwrite(STDERR, "requirements accepts[0].asset not_trimmed\n"); exit(85); }
if(!is_numeric($r0Payload["max_amount"])) { fwrite(STDERR, "requirements accepts[0].max_amount not_numeric\n"); exit(16); }
if((float)$r0Payload["max_amount"] <= 0) { fwrite(STDERR, "requirements accepts[0].max_amount not_positive\n"); exit(99); }
if(trim($r0Payload["pay_to"]) !== $r0Payload["pay_to"]) { fwrite(STDERR, "requirements accepts[0].pay_to not_trimmed\n"); exit(17); }
$platformFee = $j["data"]["platform_fee"] ?? null;
if(!is_array($platformFee)) { fwrite(STDERR, "requirements platform_fee missing_or_invalid\n"); exit(88); }
$feeBps = $platformFee["fee_bps"] ?? null;
if(!is_numeric((string)$feeBps)) { fwrite(STDERR, "requirements platform_fee.fee_bps not_numeric\n"); exit(89); }
if((float)$feeBps < 0) { fwrite(STDERR, "requirements platform_fee.fee_bps negative\n"); exit(90); }
if((float)$feeBps > 10000) { fwrite(STDERR, "requirements platform_fee.fee_bps above_max\n"); exit(105); }
$feeAppliesTo = (string)($platformFee["applies_to"] ?? "");
if($feeAppliesTo !== "paid_interactions_only") { fwrite(STDERR, "requirements platform_fee.applies_to invalid_value\n"); exit(91); }
$amountPolicy = $j["data"]["amount_policy"] ?? null;
if(!is_array($amountPolicy)) { fwrite(STDERR, "requirements amount_policy missing_or_invalid\n"); exit(100); }
$amountPricingPrinciple = (string)($amountPolicy["pricing_principle"] ?? "");
if($amountPricingPrinciple !== "agent_self_assessed_fair_value") { fwrite(STDERR, "requirements amount_policy.pricing_principle invalid_value\n"); exit(101); }
$amountScope = (string)($amountPolicy["scope"] ?? "");
if($amountScope !== "paid_interactions_only") { fwrite(STDERR, "requirements amount_policy.scope invalid_value\n"); exit(102); }
$amountStatement = trim((string)($amountPolicy["statement"] ?? ""));
if($amountStatement === "") { fwrite(STDERR, "requirements amount_policy.statement missing\n"); exit(103); }
if(stripos($amountStatement, "paid interactions") === false && stripos($amountStatement, "paid-interactions") === false) { fwrite(STDERR, "requirements amount_policy.statement missing_paid_interactions_wording\n"); exit(104); }
if(stripos($amountStatement, "fair") === false) { fwrite(STDERR, "requirements amount_policy.statement missing_fair_wording\n"); exit(107); }
if(stripos($amountStatement, "decide") === false) { fwrite(STDERR, "requirements amount_policy.statement missing_decide_wording\n"); exit(108); }
if(stripos($amountStatement, "pay") === false) { fwrite(STDERR, "requirements amount_policy.statement missing_pay_wording\n"); exit(109); }
if(preg_match("/^Agents\\b/", $amountStatement) !== 1) { fwrite(STDERR, "requirements amount_policy.statement invalid_prefix\n"); exit(110); }
file_put_contents($argv[7], $amountStatement);
file_put_contents($argv[6], (string)$feeBps);
file_put_contents($argv[4], json_encode($r0Payload));
$hasXPayment = false;
$hasX402Payment = false;
foreach($requestPayment as $headerName){
  if((string)$headerName === "X-PAYMENT"){ $hasXPayment = true; }
  if((string)$headerName === "X402-Payment"){ $hasX402Payment = true; }
}
if(!$hasXPayment) { fwrite(STDERR, "requirements headers.request_payment missing_X-PAYMENT\n"); exit(8); }
if(!$hasX402Payment) { fwrite(STDERR, "requirements headers.request_payment missing_X402-Payment\n"); exit(9); }
$responseReceipt = (string)($j["data"]["headers"]["response_receipt"] ?? "");
if($responseReceipt === "") { fwrite(STDERR, "requirements headers.response_receipt missing\n"); exit(14); }
if(trim($responseReceipt) !== $responseReceipt) { fwrite(STDERR, "requirements headers.response_receipt not_trimmed\n"); exit(63); }
if(strtoupper($responseReceipt) !== $responseReceipt) { fwrite(STDERR, "requirements headers.response_receipt not_uppercase\n"); exit(64); }
if($responseReceipt !== "X-PAYMENT-RESPONSE") { fwrite(STDERR, "requirements headers.response_receipt invalid_value\n"); exit(15); }
' "$tmp_body" "$requirements_mode_file" "$requirements_request_headers_file" "$requirements_accepts0_file" "$requirements_request_headers_ordered_file" "$requirements_fee_bps_file" "$requirements_amount_statement_file"
echo "[ok] requirements"

echo "[x402] pricing fee policy"
code="$(curl "${CURL_OPTS[@]}" -o "$tmp_body" -w '%{http_code}' "$BASE_URL/v1/billing/pricing")"
[[ "$code" == "200" ]] || { echo "[fail] pricing http=$code"; cat "$tmp_body"; exit 1; }
php -r '
$j=json_decode(file_get_contents($argv[1]), true);
if(!is_array($j) || !isset($j["status"])) { fwrite(STDERR, "invalid pricing envelope\n"); exit(2); }
$requirementsFeeBpsRaw = trim((string)file_get_contents($argv[2]));
if($requirementsFeeBpsRaw === "" || !is_numeric($requirementsFeeBpsRaw)) { fwrite(STDERR, "requirements fee_bps cache missing_or_invalid\n"); exit(3); }
$pricingPrinciple = (string)($j["data"]["pricing_principle"] ?? "");
if($pricingPrinciple !== "agent_self_assessed_fair_value") { fwrite(STDERR, "pricing pricing_principle invalid_value\n"); exit(12); }
$payerAutonomy = $j["data"]["payer_autonomy"] ?? null;
if(!is_array($payerAutonomy)) { fwrite(STDERR, "pricing payer_autonomy missing_or_invalid\n"); exit(13); }
$payerScope = (string)($payerAutonomy["scope"] ?? "");
if($payerScope !== "paid_interactions_only") { fwrite(STDERR, "pricing payer_autonomy.scope invalid_value\n"); exit(14); }
$payerStatement = trim((string)($payerAutonomy["statement"] ?? ""));
if($payerStatement === "") { fwrite(STDERR, "pricing payer_autonomy.statement missing\n"); exit(15); }
if(stripos($payerStatement, "paid interactions") === false && stripos($payerStatement, "paid-interactions") === false) { fwrite(STDERR, "pricing payer_autonomy.statement missing_paid_interactions_wording\n"); exit(21); }
$requirementsAmountStatement = trim((string)file_get_contents($argv[3]));
if($requirementsAmountStatement === "") { fwrite(STDERR, "requirements amount_policy.statement cache missing\n"); exit(24); }
if($payerStatement !== $requirementsAmountStatement) { fwrite(STDERR, "pricing payer_autonomy.statement mismatch_requirements\n"); exit(25); }
$policy = $j["data"]["platform_fee_policy"] ?? null;
if(!is_array($policy)) { fwrite(STDERR, "pricing platform_fee_policy missing_or_invalid\n"); exit(4); }
$policyBps = $policy["fee_bps"] ?? null;
if(!is_numeric((string)$policyBps)) { fwrite(STDERR, "pricing platform_fee_policy.fee_bps not_numeric\n"); exit(5); }
if((float)$policyBps < 0) { fwrite(STDERR, "pricing platform_fee_policy.fee_bps negative\n"); exit(6); }
if((float)$policyBps > 10000) { fwrite(STDERR, "pricing platform_fee_policy.fee_bps above_max\n"); exit(19); }
if((float)$policyBps !== (float)$requirementsFeeBpsRaw) { fwrite(STDERR, "pricing platform_fee_policy.fee_bps mismatch_requirements\n"); exit(7); }
$policyAppliesTo = (string)($policy["applies_to"] ?? "");
if($policyAppliesTo !== "paid_interactions_only") { fwrite(STDERR, "pricing platform_fee_policy.applies_to invalid_value\n"); exit(8); }
$x402Fee = $j["data"]["payment_protocols"]["x402"]["platform_fee"] ?? null;
if(!is_array($x402Fee)) { fwrite(STDERR, "pricing payment_protocols.x402.platform_fee missing_or_invalid\n"); exit(9); }
$x402FeeBps = $x402Fee["fee_bps"] ?? null;
if(!is_numeric((string)$x402FeeBps)) { fwrite(STDERR, "pricing payment_protocols.x402.platform_fee.fee_bps not_numeric\n"); exit(10); }
if((float)$x402FeeBps > 10000) { fwrite(STDERR, "pricing payment_protocols.x402.platform_fee.fee_bps above_max\n"); exit(20); }
if((float)$x402FeeBps !== (float)$requirementsFeeBpsRaw) { fwrite(STDERR, "pricing payment_protocols.x402.platform_fee.fee_bps mismatch_requirements\n"); exit(11); }
$x402PayerAutonomy = $j["data"]["payment_protocols"]["x402"]["payer_autonomy"] ?? null;
if(!is_array($x402PayerAutonomy)) { fwrite(STDERR, "pricing payment_protocols.x402.payer_autonomy missing_or_invalid\n"); exit(16); }
if((string)($x402PayerAutonomy["pricing_principle"] ?? "") !== "agent_self_assessed_fair_value") { fwrite(STDERR, "pricing payment_protocols.x402.payer_autonomy.pricing_principle invalid_value\n"); exit(17); }
if((string)($x402PayerAutonomy["scope"] ?? "") !== "paid_interactions_only") { fwrite(STDERR, "pricing payment_protocols.x402.payer_autonomy.scope invalid_value\n"); exit(18); }
$x402PayerStatement = trim((string)($x402PayerAutonomy["statement"] ?? ""));
if($x402PayerStatement === "") { fwrite(STDERR, "pricing payment_protocols.x402.payer_autonomy.statement missing\n"); exit(22); }
if(stripos($x402PayerStatement, "paid interactions") === false && stripos($x402PayerStatement, "paid-interactions") === false) { fwrite(STDERR, "pricing payment_protocols.x402.payer_autonomy.statement missing_paid_interactions_wording\n"); exit(23); }
if($x402PayerStatement !== $requirementsAmountStatement) { fwrite(STDERR, "pricing payment_protocols.x402.payer_autonomy.statement mismatch_requirements\n"); exit(26); }
' "$tmp_body" "$requirements_fee_bps_file" "$requirements_amount_statement_file"
echo "[ok] pricing-fee-policy"

echo "[x402] policy mode"
code="$(curl "${CURL_OPTS[@]}" -o "$tmp_body" -w '%{http_code}' "$BASE_URL/v1/policy")"
[[ "$code" == "200" ]] || { echo "[fail] policy http=$code"; cat "$tmp_body"; exit 1; }
php -r '
$j=json_decode(file_get_contents($argv[1]), true);
if(!is_array($j) || !isset($j["status"])) { fwrite(STDERR, "invalid policy envelope\n"); exit(2); }
$economicModel = (string)($j["data"]["economic_model"] ?? "");
if($economicModel !== "pay_what_you_want") { fwrite(STDERR, "invalid policy economic_model\n"); exit(5); }
$pricingPrinciple = (string)($j["data"]["pricing_principle"] ?? "");
if($pricingPrinciple !== "agent_self_assessed_fair_value") { fwrite(STDERR, "invalid policy pricing_principle\n"); exit(6); }
$payerAutonomy = $j["data"]["payer_autonomy"] ?? null;
if(!is_array($payerAutonomy)) { fwrite(STDERR, "invalid policy payer_autonomy\n"); exit(7); }
if((string)($payerAutonomy["scope"] ?? "") !== "paid_interactions_only") { fwrite(STDERR, "invalid policy payer_autonomy.scope\n"); exit(8); }
$payerStatement = trim((string)($payerAutonomy["statement"] ?? ""));
if($payerStatement === "") { fwrite(STDERR, "invalid policy payer_autonomy.statement\n"); exit(9); }
if(stripos($payerStatement, "paid interactions") === false && stripos($payerStatement, "paid-interactions") === false) { fwrite(STDERR, "invalid policy payer_autonomy.statement missing_paid_interactions_wording\n"); exit(12); }
$requirementsAmountStatement = trim((string)file_get_contents($argv[3]));
if($requirementsAmountStatement === "") { fwrite(STDERR, "requirements amount_policy.statement cache missing\n"); exit(16); }
if($payerStatement !== $requirementsAmountStatement) { fwrite(STDERR, "invalid policy payer_autonomy.statement mismatch_requirements\n"); exit(17); }
$mode = (string)($j["data"]["payment_protocols"]["x402"]["mode"] ?? "");
if($mode === "") { fwrite(STDERR, "missing policy x402 mode\n"); exit(3); }
if(!in_array($mode, ["disabled","optional","required"], true)) { fwrite(STDERR, "invalid policy x402 mode\n"); exit(4); }
$x402PayerAutonomy = $j["data"]["payment_protocols"]["x402"]["payer_autonomy"] ?? null;
if(!is_array($x402PayerAutonomy)) { fwrite(STDERR, "invalid policy x402 payer_autonomy\n"); exit(10); }
if((string)($x402PayerAutonomy["pricing_principle"] ?? "") !== "agent_self_assessed_fair_value") { fwrite(STDERR, "invalid policy x402 payer_autonomy.pricing_principle\n"); exit(11); }
if((string)($x402PayerAutonomy["scope"] ?? "") !== "paid_interactions_only") { fwrite(STDERR, "invalid policy x402 payer_autonomy.scope\n"); exit(13); }
$x402PayerStatement = trim((string)($x402PayerAutonomy["statement"] ?? ""));
if($x402PayerStatement === "") { fwrite(STDERR, "invalid policy x402 payer_autonomy.statement\n"); exit(14); }
if(stripos($x402PayerStatement, "paid interactions") === false && stripos($x402PayerStatement, "paid-interactions") === false) { fwrite(STDERR, "invalid policy x402 payer_autonomy.statement missing_paid_interactions_wording\n"); exit(15); }
if($x402PayerStatement !== $requirementsAmountStatement) { fwrite(STDERR, "invalid policy x402 payer_autonomy.statement mismatch_requirements\n"); exit(18); }
file_put_contents($argv[2], $mode);
' "$tmp_body" "$policy_mode_file" "$requirements_amount_statement_file"
echo "[ok] policy-mode"

echo "[x402] requirements mode parity"
code="$(curl "${CURL_OPTS[@]}" -o "$tmp_body" -w '%{http_code}' "$BASE_URL/v1/billing/x402/requirements?resource=$REQUEST_RESOURCE")"
[[ "$code" == "200" ]] || { echo "[fail] requirements-parity http=$code"; cat "$tmp_body"; exit 1; }
php -r '
$j=json_decode(file_get_contents($argv[1]), true);
if(!is_array($j) || !isset($j["status"])) { fwrite(STDERR, "invalid requirements envelope\n"); exit(2); }
$mode = (string)($j["data"]["mode"] ?? "");
$policyMode = trim((string)file_get_contents($argv[2]));
if($mode === "") { fwrite(STDERR, "missing requirements x402 mode\n"); exit(3); }
if(!in_array($mode, ["disabled","optional","required"], true)) { fwrite(STDERR, "invalid requirements x402 mode\n"); exit(4); }
if($policyMode === "") { fwrite(STDERR, "missing cached policy mode\n"); exit(5); }
if($mode !== $policyMode) { fwrite(STDERR, "x402 mode mismatch policy_vs_requirements\n"); exit(6); }
' "$tmp_body" "$policy_mode_file"
echo "[ok] requirements-mode-parity"

echo "[x402] verify without proof"
code="$(curl "${CURL_OPTS[@]}" -D "$tmp_headers" -o "$tmp_body" -w '%{http_code}' \
  -H 'Content-Type: application/json' \
  -X POST "$BASE_URL/v1/billing/x402/verify" \
  --data "{\"resource\":\"$REQUEST_RESOURCE\"}")"
[[ "$code" == "402" ]] || { echo "[fail] verify-no-proof http=$code"; cat "$tmp_body"; exit 1; }
grep -qi '^PAYMENT-REQUIRED:' "$tmp_headers" || { echo "[fail] PAYMENT-REQUIRED header missing"; cat "$tmp_headers"; exit 1; }
grep -i '^PAYMENT-REQUIRED:' "$tmp_headers" | head -n 1 | sed -E 's/^[^:]+:[[:space:]]*//' > "$payment_required_file"
if [[ "${X402_SMOKE_DEBUG:-0}" == "1" ]]; then
  echo "[debug] PAYMENT-REQUIRED payload:"
  cat "$payment_required_file"
fi
php -r '
$raw = trim((string)file_get_contents($argv[1]));
if($raw === "") { fwrite(STDERR, "empty PAYMENT-REQUIRED payload\n"); exit(2); }
$j = json_decode($raw, true);
if(!is_array($j)) { fwrite(STDERR, "PAYMENT-REQUIRED payload is not valid JSON\n"); exit(3); }
if((string)($j["protocol"] ?? "") !== "x402") { fwrite(STDERR, "PAYMENT-REQUIRED protocol!=x402\n"); exit(4); }
$x402Version = $j["x402_version"] ?? null;
if(!is_int($x402Version) && !is_float($x402Version) && !is_string($x402Version)) { fwrite(STDERR, "PAYMENT-REQUIRED x402_version missing\n"); exit(5); }
if(!is_numeric((string)$x402Version)) { fwrite(STDERR, "PAYMENT-REQUIRED x402_version not_numeric\n"); exit(6); }
if((float)$x402Version <= 0) { fwrite(STDERR, "PAYMENT-REQUIRED x402_version not_positive\n"); exit(60); }
$challengeHeader = (string)($j["headers"]["challenge"] ?? "");
if($challengeHeader === "") { fwrite(STDERR, "PAYMENT-REQUIRED headers.challenge missing\n"); exit(7); }
if(trim($challengeHeader) !== $challengeHeader) { fwrite(STDERR, "PAYMENT-REQUIRED headers.challenge not_trimmed\n"); exit(81); }
if(strtoupper($challengeHeader) !== $challengeHeader) { fwrite(STDERR, "PAYMENT-REQUIRED headers.challenge not_uppercase\n"); exit(82); }
if($challengeHeader !== "PAYMENT-REQUIRED") { fwrite(STDERR, "PAYMENT-REQUIRED headers.challenge invalid_value\n"); exit(8); }
$responseReceiptHeader = (string)($j["headers"]["response_receipt"] ?? "");
if($responseReceiptHeader === "") { fwrite(STDERR, "PAYMENT-REQUIRED headers.response_receipt missing\n"); exit(9); }
if(trim($responseReceiptHeader) !== $responseReceiptHeader) { fwrite(STDERR, "PAYMENT-REQUIRED headers.response_receipt not_trimmed\n"); exit(83); }
if(strtoupper($responseReceiptHeader) !== $responseReceiptHeader) { fwrite(STDERR, "PAYMENT-REQUIRED headers.response_receipt not_uppercase\n"); exit(84); }
if($responseReceiptHeader !== "X-PAYMENT-RESPONSE") { fwrite(STDERR, "PAYMENT-REQUIRED headers.response_receipt invalid_value\n"); exit(10); }
$challengeRequestPayment = $j["headers"]["request_payment"] ?? null;
if(!is_array($challengeRequestPayment) || count($challengeRequestPayment) < 1) { fwrite(STDERR, "PAYMENT-REQUIRED headers.request_payment missing_or_empty\n"); exit(11); }
$challengeRequestPaymentOrdered = array_map("strval", $challengeRequestPayment);
foreach($challengeRequestPaymentOrdered as $headerName){
  if(trim($headerName) !== $headerName) { fwrite(STDERR, "PAYMENT-REQUIRED headers.request_payment not_trimmed\n"); exit(66); }
  if($headerName === "") { fwrite(STDERR, "PAYMENT-REQUIRED headers.request_payment has_empty_value\n"); exit(69); }
  if(preg_match("/^[A-Za-z0-9-]+$/", $headerName) !== 1) { fwrite(STDERR, "PAYMENT-REQUIRED headers.request_payment invalid_token\n"); exit(71); }
  if(strcasecmp($headerName, "X-PAYMENT") === 0 && $headerName !== "X-PAYMENT") { fwrite(STDERR, "PAYMENT-REQUIRED headers.request_payment invalid_casing_X-PAYMENT\n"); exit(74); }
  if(strcasecmp($headerName, "X402-Payment") === 0 && $headerName !== "X402-Payment") { fwrite(STDERR, "PAYMENT-REQUIRED headers.request_payment invalid_casing_X402-Payment\n"); exit(75); }
}
if(count($challengeRequestPaymentOrdered) < 2) { fwrite(STDERR, "PAYMENT-REQUIRED headers.request_payment too_short\n"); exit(12); }
$challengeRequestPaymentSortedCheck = $challengeRequestPaymentOrdered;
sort($challengeRequestPaymentSortedCheck, SORT_STRING);
if($challengeRequestPaymentOrdered !== $challengeRequestPaymentSortedCheck) { fwrite(STDERR, "PAYMENT-REQUIRED headers.request_payment not_sorted\n"); exit(77); }
$challengeRequestPaymentUnique = array_values(array_unique($challengeRequestPaymentOrdered));
if(count($challengeRequestPaymentUnique) !== count($challengeRequestPaymentOrdered)) { fwrite(STDERR, "PAYMENT-REQUIRED headers.request_payment has_duplicates\n"); exit(13); }
$requirementsHeadersRaw = trim((string)file_get_contents($argv[4]));
if($requirementsHeadersRaw === "") { fwrite(STDERR, "requirements request_payment cache missing\n"); exit(14); }
$requirementsHeaders = json_decode($requirementsHeadersRaw, true);
if(!is_array($requirementsHeaders)) { fwrite(STDERR, "requirements request_payment cache invalid_json\n"); exit(15); }
$challengeSorted = $challengeRequestPaymentUnique;
sort($challengeSorted, SORT_STRING);
if($challengeSorted !== $requirementsHeaders) { fwrite(STDERR, "PAYMENT-REQUIRED headers.request_payment mismatch_requirements\n"); exit(16); }
$requirementsHeadersOrderedRaw = trim((string)file_get_contents($argv[6]));
if($requirementsHeadersOrderedRaw === "") { fwrite(STDERR, "requirements request_payment ordered cache missing\n"); exit(17); }
$requirementsHeadersOrdered = json_decode($requirementsHeadersOrderedRaw, true);
if(!is_array($requirementsHeadersOrdered)) { fwrite(STDERR, "requirements request_payment ordered cache invalid_json\n"); exit(18); }
$challengeOrdered = $challengeRequestPaymentOrdered;
if($challengeOrdered !== $requirementsHeadersOrdered) { fwrite(STDERR, "PAYMENT-REQUIRED headers.request_payment order_mismatch_requirements\n"); exit(19); }
$requirementsAcceptsRaw = trim((string)file_get_contents($argv[5]));
if($requirementsAcceptsRaw === "") { fwrite(STDERR, "requirements accepts[0] cache missing\n"); exit(20); }
$requirementsAccepts0 = json_decode($requirementsAcceptsRaw, true);
if(!is_array($requirementsAccepts0)) { fwrite(STDERR, "requirements accepts[0] cache invalid_json\n"); exit(21); }
$requirementsFeeBpsRaw = trim((string)file_get_contents($argv[10]));
if($requirementsFeeBpsRaw === "" || !is_numeric($requirementsFeeBpsRaw)) { fwrite(STDERR, "requirements platform_fee.fee_bps cache missing_or_invalid\n"); exit(92); }
$challengeFee = $j["platform_fee"] ?? null;
if(!is_array($challengeFee)) { fwrite(STDERR, "PAYMENT-REQUIRED platform_fee missing_or_invalid\n"); exit(93); }
$challengeFeeBps = $challengeFee["fee_bps"] ?? null;
if(!is_numeric((string)$challengeFeeBps)) { fwrite(STDERR, "PAYMENT-REQUIRED platform_fee.fee_bps not_numeric\n"); exit(94); }
if((float)$challengeFeeBps < 0) { fwrite(STDERR, "PAYMENT-REQUIRED platform_fee.fee_bps negative\n"); exit(95); }
if((float)$challengeFeeBps > 10000) { fwrite(STDERR, "PAYMENT-REQUIRED platform_fee.fee_bps above_max\n"); exit(106); }
if((float)$challengeFeeBps !== (float)$requirementsFeeBpsRaw) { fwrite(STDERR, "PAYMENT-REQUIRED platform_fee.fee_bps mismatch_requirements\n"); exit(96); }
$challengeFeeAppliesTo = (string)($challengeFee["applies_to"] ?? "");
if($challengeFeeAppliesTo !== "paid_interactions_only") { fwrite(STDERR, "PAYMENT-REQUIRED platform_fee.applies_to invalid_value\n"); exit(97); }
$challengeHasXPayment = false;
$challengeHasX402Payment = false;
foreach($challengeRequestPayment as $headerName){
  if((string)$headerName === "X-PAYMENT"){ $challengeHasXPayment = true; }
  if((string)$headerName === "X402-Payment"){ $challengeHasX402Payment = true; }
}
if(!$challengeHasXPayment) { fwrite(STDERR, "PAYMENT-REQUIRED headers.request_payment missing_X-PAYMENT\n"); exit(22); }
if(!$challengeHasX402Payment) { fwrite(STDERR, "PAYMENT-REQUIRED headers.request_payment missing_X402-Payment\n"); exit(23); }
$expectedVerifyPath = (string)$argv[7];
if($expectedVerifyPath === "") { fwrite(STDERR, "expected verify path argument missing\n"); exit(24); }
$verifyLink = (string)($j["links"]["verify"] ?? "");
if($verifyLink === "") { fwrite(STDERR, "PAYMENT-REQUIRED links.verify missing\n"); exit(25); }
if($verifyLink !== $expectedVerifyPath) { fwrite(STDERR, "PAYMENT-REQUIRED links.verify invalid_canonical_path\n"); exit(26); }
if(strpos($verifyLink, "/topos/api/v1/") !== 0) { fwrite(STDERR, "PAYMENT-REQUIRED links.verify invalid_namespace_scope\n"); exit(27); }
$verifyQuery = parse_url($verifyLink, PHP_URL_QUERY);
if($verifyQuery !== null && $verifyQuery !== "") { fwrite(STDERR, "PAYMENT-REQUIRED links.verify has_query_string\n"); exit(28); }
$verifyUrlRaw = (string)($j["verify_url"] ?? "");
if($verifyUrlRaw !== "" && $verifyUrlRaw !== $expectedVerifyPath) { fwrite(STDERR, "PAYMENT-REQUIRED verify_url invalid_canonical_path\n"); exit(29); }
$verifyUrl = $verifyUrlRaw;
if($verifyUrl === "") { $verifyUrl = (string)($j["links"]["verify"] ?? ""); }
if($verifyUrl === "") { fwrite(STDERR, "PAYMENT-REQUIRED verify_url/links.verify missing\n"); exit(30); }
$requirementsUrl = (string)($j["links"]["requirements"] ?? "");
if($requirementsUrl === "") { fwrite(STDERR, "PAYMENT-REQUIRED links.requirements missing\n"); exit(31); }
if(strpos($requirementsUrl, "/topos/api/v1/") !== 0) { fwrite(STDERR, "PAYMENT-REQUIRED links.requirements invalid_namespace_scope\n"); exit(32); }
$expectedRequirementsPath = (string)$argv[8];
if($expectedRequirementsPath === "") { fwrite(STDERR, "expected requirements path argument missing\n"); exit(33); }
if($requirementsUrl !== $expectedRequirementsPath) { fwrite(STDERR, "PAYMENT-REQUIRED links.requirements invalid_canonical_path\n"); exit(34); }
$requirementsQuery = parse_url($requirementsUrl, PHP_URL_QUERY);
if($requirementsQuery !== null && $requirementsQuery !== "") { fwrite(STDERR, "PAYMENT-REQUIRED links.requirements has_query_string\n"); exit(35); }
$pricingUrl = (string)($j["links"]["pricing"] ?? "");
if($pricingUrl === "") { fwrite(STDERR, "PAYMENT-REQUIRED links.pricing missing\n"); exit(36); }
if(strpos($pricingUrl, "/topos/api/v1/") !== 0) { fwrite(STDERR, "PAYMENT-REQUIRED links.pricing invalid_namespace_scope\n"); exit(37); }
$expectedPricingPath = (string)$argv[9];
if($expectedPricingPath === "") { fwrite(STDERR, "expected pricing path argument missing\n"); exit(38); }
if($pricingUrl !== $expectedPricingPath) { fwrite(STDERR, "PAYMENT-REQUIRED links.pricing invalid_canonical_path\n"); exit(39); }
$pricingQuery = parse_url($pricingUrl, PHP_URL_QUERY);
if($pricingQuery !== null && $pricingQuery !== "") { fwrite(STDERR, "PAYMENT-REQUIRED links.pricing has_query_string\n"); exit(40); }
$resource = (string)($j["resource"] ?? "");
$expectedResource = (string)$argv[3];
if($expectedResource === "") { fwrite(STDERR, "expected resource argument missing\n"); exit(41); }
if($resource === "") { fwrite(STDERR, "PAYMENT-REQUIRED resource missing\n"); exit(42); }
if(strpos($resource, "/topos/api/v1/") !== 0) { fwrite(STDERR, "PAYMENT-REQUIRED resource invalid_namespace_scope\n"); exit(43); }
$resourceQuery = parse_url($resource, PHP_URL_QUERY);
if($resourceQuery !== null && $resourceQuery !== "") { fwrite(STDERR, "PAYMENT-REQUIRED resource has_query_string\n"); exit(44); }
if($resource !== $expectedResource) { fwrite(STDERR, "PAYMENT-REQUIRED resource mismatch requested_resource\n"); exit(45); }
$challengeMode = (string)($j["mode"] ?? "");
$requirementsMode = trim((string)file_get_contents($argv[2]));
if($challengeMode === "") { fwrite(STDERR, "PAYMENT-REQUIRED mode missing\n"); exit(46); }
if($requirementsMode === "") { fwrite(STDERR, "requirements mode cache missing\n"); exit(47); }
if($challengeMode !== $requirementsMode) { fwrite(STDERR, "PAYMENT-REQUIRED mode mismatch requirements_mode\n"); exit(48); }
$accepts = $j["accepts"] ?? null;
if(!is_array($accepts) || count($accepts) < 1) { fwrite(STDERR, "PAYMENT-REQUIRED accepts missing_or_empty\n"); exit(49); }
$a0 = is_array($accepts[0] ?? null) ? $accepts[0] : [];
if((string)($a0["network"] ?? "") === "") { fwrite(STDERR, "PAYMENT-REQUIRED accepts[0].network missing\n"); exit(50); }
if(trim((string)($a0["network"] ?? "")) !== (string)($a0["network"] ?? "")) { fwrite(STDERR, "PAYMENT-REQUIRED accepts[0].network not_trimmed\n"); exit(98); }
if((string)($a0["asset"] ?? "") === "") { fwrite(STDERR, "PAYMENT-REQUIRED accepts[0].asset missing\n"); exit(51); }
if(trim((string)($a0["asset"] ?? "")) !== (string)($a0["asset"] ?? "")) { fwrite(STDERR, "PAYMENT-REQUIRED accepts[0].asset not_trimmed\n"); exit(86); }
if((string)($a0["max_amount"] ?? "") === "") { fwrite(STDERR, "PAYMENT-REQUIRED accepts[0].max_amount missing\n"); exit(52); }
if(!is_numeric((string)($a0["max_amount"] ?? ""))) { fwrite(STDERR, "PAYMENT-REQUIRED accepts[0].max_amount not_numeric\n"); exit(53); }
if((float)((string)($a0["max_amount"] ?? "0")) <= 0) { fwrite(STDERR, "PAYMENT-REQUIRED accepts[0].max_amount not_positive\n"); exit(104); }
if((string)($a0["pay_to"] ?? "") === "") { fwrite(STDERR, "PAYMENT-REQUIRED accepts[0].pay_to missing\n"); exit(54); }
$payTo = (string)($a0["pay_to"] ?? "");
if(trim($payTo) !== $payTo) { fwrite(STDERR, "PAYMENT-REQUIRED accepts[0].pay_to not_trimmed\n"); exit(55); }
$c0 = [
  "network" => (string)($a0["network"] ?? ""),
  "asset" => (string)($a0["asset"] ?? ""),
  "max_amount" => (string)($a0["max_amount"] ?? ""),
  "pay_to" => (string)($a0["pay_to"] ?? ""),
];
if($c0 !== $requirementsAccepts0) { fwrite(STDERR, "PAYMENT-REQUIRED accepts[0] mismatch_requirements\n"); exit(56); }
' "$payment_required_file" "$requirements_mode_file" "$REQUEST_RESOURCE" "$requirements_request_headers_file" "$requirements_accepts0_file" "$requirements_request_headers_ordered_file" "$EXPECTED_VERIFY_PATH" "$EXPECTED_REQUIREMENTS_PATH" "$EXPECTED_PRICING_PATH" "$requirements_fee_bps_file"
php -r '
$j=json_decode(file_get_contents($argv[1]), true);
if(!is_array($j) || !isset($j["status"])) { fwrite(STDERR, "invalid verify envelope\n"); exit(2); }
if(!isset($j["data"]["accepted"]) || $j["data"]["accepted"] !== false) { fwrite(STDERR, "expected accepted=false\n"); exit(3); }
if((string)($j["data"]["mode"] ?? "") === "") { fwrite(STDERR, "expected non-empty mode for missing-proof response\n"); exit(4); }
if((string)($j["data"]["reason"] ?? "") === "") { fwrite(STDERR, "expected non-empty reason for missing-proof response\n"); exit(5); }
$platformFee = $j["data"]["platform_fee"] ?? null;
if(!is_array($platformFee)) { fwrite(STDERR, "expected platform_fee in missing-proof response\n"); exit(6); }
$feeBps = $platformFee["fee_bps"] ?? null;
if(!is_numeric((string)$feeBps)) { fwrite(STDERR, "expected numeric platform_fee.fee_bps in missing-proof response\n"); exit(7); }
if((float)$feeBps < 0) { fwrite(STDERR, "expected non-negative platform_fee.fee_bps in missing-proof response\n"); exit(8); }
if((float)$feeBps > 10000) { fwrite(STDERR, "expected platform_fee.fee_bps<=10000 in missing-proof response\n"); exit(11); }
if(($platformFee["applied"] ?? null) !== false) { fwrite(STDERR, "expected platform_fee.applied=false in missing-proof response\n"); exit(9); }
if((string)($platformFee["applies_to"] ?? "") !== "paid_interactions_only") { fwrite(STDERR, "expected platform_fee.applies_to=paid_interactions_only in missing-proof response\n"); exit(10); }
' "$tmp_body"
echo "[ok] verify-no-proof"

echo "[x402] verify with signature"
code="$(curl "${CURL_OPTS[@]}" -o "$tmp_body" -w '%{http_code}' \
  -H 'Content-Type: application/json' \
  -H 'PAYMENT-SIGNATURE: stub-signature' \
  -X POST "$BASE_URL/v1/billing/x402/verify" \
  --data "{\"resource\":\"$REQUEST_RESOURCE\"}")"
[[ "$code" == "200" ]] || { echo "[fail] verify-with-signature http=$code"; cat "$tmp_body"; exit 1; }
php -r '
$j=json_decode(file_get_contents($argv[1]), true);
if(!is_array($j) || !isset($j["status"])) { fwrite(STDERR, "invalid verify envelope\n"); exit(2); }
if(!isset($j["data"]["accepted"]) || $j["data"]["accepted"] !== true) { fwrite(STDERR, "expected accepted=true\n"); exit(3); }
if((string)($j["data"]["mode"] ?? "") === "") { fwrite(STDERR, "expected non-empty mode for success response\n"); exit(4); }
if((string)($j["data"]["reason"] ?? "") === "") { fwrite(STDERR, "expected non-empty reason for success response\n"); exit(5); }
$platformFee = $j["data"]["platform_fee"] ?? null;
if(!is_array($platformFee)) { fwrite(STDERR, "expected platform_fee in success response\n"); exit(6); }
$feeBps = $platformFee["fee_bps"] ?? null;
if(!is_numeric((string)$feeBps)) { fwrite(STDERR, "expected numeric platform_fee.fee_bps in success response\n"); exit(7); }
if((float)$feeBps < 0) { fwrite(STDERR, "expected non-negative platform_fee.fee_bps in success response\n"); exit(8); }
if((float)$feeBps > 10000) { fwrite(STDERR, "expected platform_fee.fee_bps<=10000 in success response\n"); exit(11); }
if(($platformFee["applied"] ?? null) !== true) { fwrite(STDERR, "expected platform_fee.applied=true in success response\n"); exit(9); }
if((string)($platformFee["applies_to"] ?? "") !== "paid_interactions_only") { fwrite(STDERR, "expected platform_fee.applies_to=paid_interactions_only in success response\n"); exit(10); }
' "$tmp_body"
echo "[ok] verify-with-signature"

echo "x402_smoke: pass"

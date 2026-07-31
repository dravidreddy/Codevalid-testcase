#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"

RESPONSE_HEADERS="/tmp/ping_response_indicates_operational_status_headers_${CASE_SUFFIX}.txt"
RESPONSE_BODY="/tmp/ping_response_indicates_operational_status_body_${CASE_SUFFIX}.txt"

cleanup_files() {
  rm -f "$RESPONSE_HEADERS" "$RESPONSE_BODY"
}
trap cleanup_files EXIT

# Given
echo "STEP: Given — prepare operational status verification"
echo "PREREQ: Using BASE_URL=${BASE_URL}"

# When
echo "STEP: When — request operational ping response"
echo "REQUEST_HEADERS: Accept: application/json"
echo "REQUEST_BODY: <empty>"

HTTP_STATUS=$(curl -sS -D "$RESPONSE_HEADERS" -o "$RESPONSE_BODY" -w '%{http_code}' \
  -H 'Accept: application/json' \
  "$BASE_URL/api/ping")

echo "RESPONSE_HEADERS:"
cat "$RESPONSE_HEADERS"
echo "RESPONSE_BODY:"
cat "$RESPONSE_BODY"
echo "RESPONSE_STATUS: ${HTTP_STATUS}"

# Then
echo "STEP: Then — verify response indicates operational status"
[ "$HTTP_STATUS" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${HTTP_STATUS}"; exit 1; }

jq empty "$RESPONSE_BODY" >/dev/null 2>&1 || {
  echo "ASSERTION_FAILED: response body is not valid JSON"
  exit 1
}

STATUS_VALUE=$(jq -r '(.status // .serviceStatus // .state // empty)' "$RESPONSE_BODY")

[ -n "$STATUS_VALUE" ] || {
  echo "ASSERTION_FAILED: expected operational status field in response"
  exit 1
}

printf '%s' "$STATUS_VALUE" | grep -Ei 'ok|operational|healthy|up' >/dev/null 2>&1 || {
  echo "ASSERTION_FAILED: expected operational status indicator got ${STATUS_VALUE}"
  exit 1
}

# Cleanup
echo "STEP: Cleanup — no cleanup required for stateless ping endpoint"

echo "CODEVALID_TEST_ASSERTION_OK:ping_response_indicates_operational_status"

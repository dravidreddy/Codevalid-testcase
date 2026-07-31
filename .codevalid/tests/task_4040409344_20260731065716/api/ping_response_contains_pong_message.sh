#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"

RESPONSE_BODY_FILE="/tmp/ping_response_contains_pong_message_response_body_${CASE_SUFFIX}.txt"
RESPONSE_HEADERS_FILE="/tmp/ping_response_contains_pong_message_response_headers_${CASE_SUFFIX}.txt"

cleanup_files() {
  rm -f "$RESPONSE_BODY_FILE" "$RESPONSE_HEADERS_FILE"
}

trap cleanup_files EXIT

# Given
echo "STEP: Given — prepare pong message validation"
echo "PREREQ: using BASE_URL=$BASE_URL"

# When
echo "STEP: When — send GET request to /api/ping"
echo "REQUEST_HEADERS: Accept: application/json"
echo "REQUEST_BODY: <empty>"

HTTP_STATUS="$(curl -sS -o "$RESPONSE_BODY_FILE" -D "$RESPONSE_HEADERS_FILE" -w '%{http_code}' \
  -H 'Accept: application/json' \
  "$BASE_URL/api/ping")"

echo "RESPONSE_HEADERS:"
cat "$RESPONSE_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$RESPONSE_BODY_FILE"
echo "RESPONSE_STATUS: $HTTP_STATUS"

# Then
echo "STEP: Then — verify pong message is present"
[ "$HTTP_STATUS" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${HTTP_STATUS}"; exit 1; }
grep -qi 'pong' "$RESPONSE_BODY_FILE" || { echo "ASSERTION_FAILED: expected pong message in response body"; exit 1; }

# Cleanup
echo "STEP: Cleanup — remove temporary response artifacts"
cleanup_files

echo "CODEVALID_TEST_ASSERTION_OK:ping_response_contains_pong_message"

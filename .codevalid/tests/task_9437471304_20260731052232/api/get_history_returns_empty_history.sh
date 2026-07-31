#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"

RESPONSE_BODY_FILE="/tmp/get_history_returns_empty_history_response_${CASE_SUFFIX}.txt"
RESPONSE_HEADERS_FILE="/tmp/get_history_returns_empty_history_headers_${CASE_SUFFIX}.txt"
CLEAR_BODY_FILE="/tmp/get_history_returns_empty_history_clear_body_${CASE_SUFFIX}.txt"
CLEAR_HEADERS_FILE="/tmp/get_history_returns_empty_history_clear_headers_${CASE_SUFFIX}.txt"

cleanup_files() {
  rm -f "$RESPONSE_BODY_FILE" "$RESPONSE_HEADERS_FILE" "$CLEAR_BODY_FILE" "$CLEAR_HEADERS_FILE"
}
trap cleanup_files EXIT

# Given

echo "STEP: Given — ensure chat history is empty"
echo "PREREQ: clearing chat history through API"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: {}"
CLEAR_STATUS=$(curl -sS -o "$CLEAR_BODY_FILE" -D "$CLEAR_HEADERS_FILE" -w '%{http_code}' -X POST "$BASE_URL/clear-history")
echo "RESPONSE_HEADERS:"
cat "$CLEAR_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$CLEAR_BODY_FILE"
echo "RESPONSE_STATUS: $CLEAR_STATUS"
[ "$CLEAR_STATUS" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${CLEAR_STATUS}"; exit 1; }

# When

echo "STEP: When — retrieve empty chat history"
echo "REQUEST_HEADERS: Accept: application/json"
echo "REQUEST_BODY: <empty>"
STATUS_CODE=$(curl -sS -o "$RESPONSE_BODY_FILE" -D "$RESPONSE_HEADERS_FILE" -w '%{http_code}' "$BASE_URL/history")
echo "RESPONSE_HEADERS:"
cat "$RESPONSE_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$RESPONSE_BODY_FILE"
echo "RESPONSE_STATUS: $STATUS_CODE"

# Then

echo "STEP: Then — verify empty history response"
[ "$STATUS_CODE" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${STATUS_CODE}"; exit 1; }
grep -qi "content-type: application/json" "$RESPONSE_HEADERS_FILE" || { echo "ASSERTION_FAILED: expected application/json content type"; exit 1; }
grep -F '"history":[]' "$RESPONSE_BODY_FILE" || { echo "ASSERTION_FAILED: expected empty history array"; exit 1; }

# Cleanup

echo "STEP: Cleanup — clear history after assertions"
curl -sS -o /dev/null -X POST "$BASE_URL/clear-history"

echo "CODEVALID_TEST_ASSERTION_OK:get_history_returns_empty_history"

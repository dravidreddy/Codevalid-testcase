#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"

CLEAR_HEADERS="/tmp/clear_history_when_already_empty_clear_headers_${CASE_SUFFIX}.txt"
CLEAR_BODY="/tmp/clear_history_when_already_empty_clear_body_${CASE_SUFFIX}.txt"
HISTORY_HEADERS="/tmp/clear_history_when_already_empty_history_headers_${CASE_SUFFIX}.txt"
HISTORY_BODY="/tmp/clear_history_when_already_empty_history_body_${CASE_SUFFIX}.txt"

cleanup_files() {
  rm -f "$CLEAR_HEADERS" "$CLEAR_BODY" "$HISTORY_HEADERS" "$HISTORY_BODY"
}
trap cleanup_files EXIT

# Given

echo "STEP: Given — ensure chat history is already empty"
echo "PREREQ: clear any existing chat history before test"
curl -sS -X POST "$BASE_URL/api/clear-history" >/dev/null 2>&1 || true

# When

echo "STEP: When — clear an already empty chat history"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: {}"
CLEAR_STATUS=$(curl -sS -o "$CLEAR_BODY" -D "$CLEAR_HEADERS" -w '%{http_code}' -X POST "$BASE_URL/api/clear-history" -H 'Content-Type: application/json')
echo "RESPONSE_HEADERS:"
cat "$CLEAR_HEADERS"
echo "RESPONSE_BODY:"
cat "$CLEAR_BODY"
echo "RESPONSE_STATUS: ${CLEAR_STATUS}"

# Then

echo "STEP: Then — verify clear request succeeds and history remains empty"
[ "$CLEAR_STATUS" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${CLEAR_STATUS}"; exit 1; }
grep -q '"status":"cleared"' "$CLEAR_BODY" || { echo "ASSERTION_FAILED: expected cleared status response"; exit 1; }

echo "REQUEST_HEADERS: Accept: application/json"
echo "REQUEST_BODY: <empty>"
HISTORY_STATUS=$(curl -sS -o "$HISTORY_BODY" -D "$HISTORY_HEADERS" -w '%{http_code}' "$BASE_URL/api/history")
echo "RESPONSE_HEADERS:"
cat "$HISTORY_HEADERS"
echo "RESPONSE_BODY:"
cat "$HISTORY_BODY"
echo "RESPONSE_STATUS: ${HISTORY_STATUS}"
[ "$HISTORY_STATUS" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${HISTORY_STATUS}"; exit 1; }
grep -q '"history":\[\]' "$HISTORY_BODY" || { echo "ASSERTION_FAILED: expected empty history array"; exit 1; }

# Cleanup

echo "STEP: Cleanup — leave chat history empty"
curl -sS -X POST "$BASE_URL/api/clear-history" >/dev/null 2>&1 || true

echo "CODEVALID_TEST_ASSERTION_OK:clear_history_when_already_empty"

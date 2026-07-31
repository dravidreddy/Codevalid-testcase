#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"

CHAT_HEADERS="/tmp/clear_history_multiple_consecutive_requests_chat_headers_${CASE_SUFFIX}.txt"
CHAT_BODY="/tmp/clear_history_multiple_consecutive_requests_chat_body_${CASE_SUFFIX}.txt"
FIRST_CLEAR_HEADERS="/tmp/clear_history_multiple_consecutive_requests_first_clear_headers_${CASE_SUFFIX}.txt"
FIRST_CLEAR_BODY="/tmp/clear_history_multiple_consecutive_requests_first_clear_body_${CASE_SUFFIX}.txt"
SECOND_CLEAR_HEADERS="/tmp/clear_history_multiple_consecutive_requests_second_clear_headers_${CASE_SUFFIX}.txt"
SECOND_CLEAR_BODY="/tmp/clear_history_multiple_consecutive_requests_second_clear_body_${CASE_SUFFIX}.txt"
HISTORY_HEADERS="/tmp/clear_history_multiple_consecutive_requests_history_headers_${CASE_SUFFIX}.txt"
HISTORY_BODY="/tmp/clear_history_multiple_consecutive_requests_history_body_${CASE_SUFFIX}.txt"

cleanup_files() {
  rm -f "$CHAT_HEADERS" "$CHAT_BODY" "$FIRST_CLEAR_HEADERS" "$FIRST_CLEAR_BODY" "$SECOND_CLEAR_HEADERS" "$SECOND_CLEAR_BODY" "$HISTORY_HEADERS" "$HISTORY_BODY"
}
trap cleanup_files EXIT

# Given

echo "STEP: Given — populate chat history before repeated clears"
echo "PREREQ: reset chat history to a known state"
curl -sS -X POST "$BASE_URL/api/clear-history" >/dev/null 2>&1 || true

echo "PREREQ: create chat history entry"
echo "REQUEST_HEADERS: Content-Type: application/json"
CHAT_REQUEST_BODY="{\"message\":\"repeat clear history ${CASE_SUFFIX}\"}"
echo "REQUEST_BODY: ${CHAT_REQUEST_BODY}"
CHAT_STATUS=$(curl -sS -o "$CHAT_BODY" -D "$CHAT_HEADERS" -w '%{http_code}' -X POST "$BASE_URL/api/chat" -H 'Content-Type: application/json' -d "$CHAT_REQUEST_BODY")
echo "RESPONSE_HEADERS:"
cat "$CHAT_HEADERS"
echo "RESPONSE_BODY:"
cat "$CHAT_BODY"
echo "RESPONSE_STATUS: ${CHAT_STATUS}"
[ "$CHAT_STATUS" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${CHAT_STATUS}"; exit 1; }

# When

echo "STEP: When — send consecutive clear history requests"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: {}"
FIRST_CLEAR_STATUS=$(curl -sS -o "$FIRST_CLEAR_BODY" -D "$FIRST_CLEAR_HEADERS" -w '%{http_code}' -X POST "$BASE_URL/api/clear-history" -H 'Content-Type: application/json')
echo "RESPONSE_HEADERS:"
cat "$FIRST_CLEAR_HEADERS"
echo "RESPONSE_BODY:"
cat "$FIRST_CLEAR_BODY"
echo "RESPONSE_STATUS: ${FIRST_CLEAR_STATUS}"

SECOND_CLEAR_STATUS=$(curl -sS -o "$SECOND_CLEAR_BODY" -D "$SECOND_CLEAR_HEADERS" -w '%{http_code}' -X POST "$BASE_URL/api/clear-history" -H 'Content-Type: application/json')
echo "RESPONSE_HEADERS:"
cat "$SECOND_CLEAR_HEADERS"
echo "RESPONSE_BODY:"
cat "$SECOND_CLEAR_BODY"
echo "RESPONSE_STATUS: ${SECOND_CLEAR_STATUS}"

# Then

echo "STEP: Then — verify both clear requests succeed and history is empty"
[ "$FIRST_CLEAR_STATUS" = "200" ] || { echo "ASSERTION_FAILED: expected first HTTP 200 got ${FIRST_CLEAR_STATUS}"; exit 1; }
[ "$SECOND_CLEAR_STATUS" = "200" ] || { echo "ASSERTION_FAILED: expected second HTTP 200 got ${SECOND_CLEAR_STATUS}"; exit 1; }
grep -q '"status":"cleared"' "$FIRST_CLEAR_BODY" || { echo "ASSERTION_FAILED: expected first cleared status response"; exit 1; }
grep -q '"status":"cleared"' "$SECOND_CLEAR_BODY" || { echo "ASSERTION_FAILED: expected second cleared status response"; exit 1; }

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

echo "STEP: Cleanup — ensure chat history remains empty"
curl -sS -X POST "$BASE_URL/api/clear-history" >/dev/null 2>&1 || true

echo "CODEVALID_TEST_ASSERTION_OK:clear_history_multiple_consecutive_requests"

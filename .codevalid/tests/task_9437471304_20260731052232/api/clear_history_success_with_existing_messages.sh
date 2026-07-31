#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"

CHAT_HEADERS="/tmp/clear_history_success_with_existing_messages_chat_headers_${CASE_SUFFIX}.txt"
CHAT_BODY="/tmp/clear_history_success_with_existing_messages_chat_body_${CASE_SUFFIX}.txt"
CLEAR_HEADERS="/tmp/clear_history_success_with_existing_messages_clear_headers_${CASE_SUFFIX}.txt"
CLEAR_BODY="/tmp/clear_history_success_with_existing_messages_clear_body_${CASE_SUFFIX}.txt"
HISTORY_HEADERS="/tmp/clear_history_success_with_existing_messages_history_headers_${CASE_SUFFIX}.txt"
HISTORY_BODY="/tmp/clear_history_success_with_existing_messages_history_body_${CASE_SUFFIX}.txt"

cleanup_files() {
  rm -f "$CHAT_HEADERS" "$CHAT_BODY" "$CLEAR_HEADERS" "$CLEAR_BODY" "$HISTORY_HEADERS" "$HISTORY_BODY"
}
trap cleanup_files EXIT

# Given

echo "STEP: Given — create chat history messages"
echo "PREREQ: clear any existing chat history"
curl -sS -X POST "$BASE_URL/api/clear-history" >/dev/null 2>&1 || true

echo "PREREQ: submit a chat message to populate history"
echo "REQUEST_HEADERS: Content-Type: application/json"
CHAT_REQUEST_BODY="{\"message\":\"hello from clear history success ${CASE_SUFFIX}\"}"
echo "REQUEST_BODY: ${CHAT_REQUEST_BODY}"
CHAT_STATUS=$(curl -sS -o "$CHAT_BODY" -D "$CHAT_HEADERS" -w '%{http_code}' -X POST "$BASE_URL/api/chat" -H 'Content-Type: application/json' -d "$CHAT_REQUEST_BODY")
echo "RESPONSE_HEADERS:"
cat "$CHAT_HEADERS"
echo "RESPONSE_BODY:"
cat "$CHAT_BODY"
echo "RESPONSE_STATUS: ${CHAT_STATUS}"
[ "$CHAT_STATUS" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${CHAT_STATUS}"; exit 1; }

# When

echo "STEP: When — clear the existing chat history"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: {}"
CLEAR_STATUS=$(curl -sS -o "$CLEAR_BODY" -D "$CLEAR_HEADERS" -w '%{http_code}' -X POST "$BASE_URL/api/clear-history" -H 'Content-Type: application/json')
echo "RESPONSE_HEADERS:"
cat "$CLEAR_HEADERS"
echo "RESPONSE_BODY:"
cat "$CLEAR_BODY"
echo "RESPONSE_STATUS: ${CLEAR_STATUS}"

# Then

echo "STEP: Then — verify history was cleared"
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

echo "STEP: Cleanup — ensure chat history is empty"
curl -sS -X POST "$BASE_URL/api/clear-history" >/dev/null 2>&1 || true

echo "CODEVALID_TEST_ASSERTION_OK:clear_history_success_with_existing_messages"

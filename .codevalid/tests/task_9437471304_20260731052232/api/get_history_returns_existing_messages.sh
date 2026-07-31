#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USER_MESSAGE="history-seed-${CASE_SUFFIX}"

CHAT_BODY_FILE="/tmp/get_history_returns_existing_messages_chat_body_${CASE_SUFFIX}.txt"
CHAT_HEADERS_FILE="/tmp/get_history_returns_existing_messages_chat_headers_${CASE_SUFFIX}.txt"
RESPONSE_BODY_FILE="/tmp/get_history_returns_existing_messages_response_${CASE_SUFFIX}.txt"
RESPONSE_HEADERS_FILE="/tmp/get_history_returns_existing_messages_headers_${CASE_SUFFIX}.txt"
CLEAR_BODY_FILE="/tmp/get_history_returns_existing_messages_clear_body_${CASE_SUFFIX}.txt"
CLEAR_HEADERS_FILE="/tmp/get_history_returns_existing_messages_clear_headers_${CASE_SUFFIX}.txt"

cleanup_files() {
  rm -f "$CHAT_BODY_FILE" "$CHAT_HEADERS_FILE" "$RESPONSE_BODY_FILE" "$RESPONSE_HEADERS_FILE" "$CLEAR_BODY_FILE" "$CLEAR_HEADERS_FILE"
}
trap cleanup_files EXIT

# Given

echo "STEP: Given — create chat history messages"
echo "PREREQ: clearing existing chat history"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: {}"
CLEAR_STATUS=$(curl -sS -o "$CLEAR_BODY_FILE" -D "$CLEAR_HEADERS_FILE" -w '%{http_code}' -X POST "$BASE_URL/clear-history")
echo "RESPONSE_HEADERS:"
cat "$CLEAR_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$CLEAR_BODY_FILE"
echo "RESPONSE_STATUS: $CLEAR_STATUS"
[ "$CLEAR_STATUS" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${CLEAR_STATUS}"; exit 1; }

echo "PREREQ: sending chat message to populate history"
CHAT_REQUEST=$(printf '{"message":"%s"}' "$USER_MESSAGE")
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $CHAT_REQUEST"
CHAT_STATUS=$(curl -sS -o "$CHAT_BODY_FILE" -D "$CHAT_HEADERS_FILE" -w '%{http_code}' -H 'Content-Type: application/json' -X POST "$BASE_URL/chat" -d "$CHAT_REQUEST")
echo "RESPONSE_HEADERS:"
cat "$CHAT_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$CHAT_BODY_FILE"
echo "RESPONSE_STATUS: $CHAT_STATUS"
[ "$CHAT_STATUS" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${CHAT_STATUS}"; exit 1; }

# When

echo "STEP: When — retrieve populated chat history"
echo "REQUEST_HEADERS: Accept: application/json"
echo "REQUEST_BODY: <empty>"
STATUS_CODE=$(curl -sS -o "$RESPONSE_BODY_FILE" -D "$RESPONSE_HEADERS_FILE" -w '%{http_code}' "$BASE_URL/history")
echo "RESPONSE_HEADERS:"
cat "$RESPONSE_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$RESPONSE_BODY_FILE"
echo "RESPONSE_STATUS: $STATUS_CODE"

# Then

echo "STEP: Then — verify existing messages are returned"
[ "$STATUS_CODE" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${STATUS_CODE}"; exit 1; }
grep -F '"history":' "$RESPONSE_BODY_FILE" || { echo "ASSERTION_FAILED: expected history field in response"; exit 1; }
grep -F "$USER_MESSAGE" "$RESPONSE_BODY_FILE" || { echo "ASSERTION_FAILED: expected seeded user message in history"; exit 1; }
grep -F 'Echo response:' "$RESPONSE_BODY_FILE" || { echo "ASSERTION_FAILED: expected bot reply in history"; exit 1; }

# Cleanup

echo "STEP: Cleanup — clear chat history"
curl -sS -o /dev/null -X POST "$BASE_URL/clear-history"

echo "CODEVALID_TEST_ASSERTION_OK:get_history_returns_existing_messages"

#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
FIRST_MESSAGE="first-message-${CASE_SUFFIX}"
SECOND_MESSAGE="second-message-${CASE_SUFFIX}"

FIRST_BODY_FILE="/tmp/get_history_preserves_message_order_first_body_${CASE_SUFFIX}.txt"
FIRST_HEADERS_FILE="/tmp/get_history_preserves_message_order_first_headers_${CASE_SUFFIX}.txt"
SECOND_BODY_FILE="/tmp/get_history_preserves_message_order_second_body_${CASE_SUFFIX}.txt"
SECOND_HEADERS_FILE="/tmp/get_history_preserves_message_order_second_headers_${CASE_SUFFIX}.txt"
RESPONSE_BODY_FILE="/tmp/get_history_preserves_message_order_response_${CASE_SUFFIX}.txt"
RESPONSE_HEADERS_FILE="/tmp/get_history_preserves_message_order_headers_${CASE_SUFFIX}.txt"
CLEAR_BODY_FILE="/tmp/get_history_preserves_message_order_clear_body_${CASE_SUFFIX}.txt"
CLEAR_HEADERS_FILE="/tmp/get_history_preserves_message_order_clear_headers_${CASE_SUFFIX}.txt"

cleanup_files() {
  rm -f "$FIRST_BODY_FILE" "$FIRST_HEADERS_FILE" "$SECOND_BODY_FILE" "$SECOND_HEADERS_FILE" "$RESPONSE_BODY_FILE" "$RESPONSE_HEADERS_FILE" "$CLEAR_BODY_FILE" "$CLEAR_HEADERS_FILE"
}
trap cleanup_files EXIT

# Given

echo "STEP: Given — populate ordered chat history"
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

FIRST_REQUEST=$(printf '{"message":"%s"}' "$FIRST_MESSAGE")
echo "PREREQ: sending first ordered message"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $FIRST_REQUEST"
FIRST_STATUS=$(curl -sS -o "$FIRST_BODY_FILE" -D "$FIRST_HEADERS_FILE" -w '%{http_code}' -H 'Content-Type: application/json' -X POST "$BASE_URL/chat" -d "$FIRST_REQUEST")
echo "RESPONSE_HEADERS:"
cat "$FIRST_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$FIRST_BODY_FILE"
echo "RESPONSE_STATUS: $FIRST_STATUS"
[ "$FIRST_STATUS" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${FIRST_STATUS}"; exit 1; }

SECOND_REQUEST=$(printf '{"message":"%s"}' "$SECOND_MESSAGE")
echo "PREREQ: sending second ordered message"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $SECOND_REQUEST"
SECOND_STATUS=$(curl -sS -o "$SECOND_BODY_FILE" -D "$SECOND_HEADERS_FILE" -w '%{http_code}' -H 'Content-Type: application/json' -X POST "$BASE_URL/chat" -d "$SECOND_REQUEST")
echo "RESPONSE_HEADERS:"
cat "$SECOND_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$SECOND_BODY_FILE"
echo "RESPONSE_STATUS: $SECOND_STATUS"
[ "$SECOND_STATUS" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${SECOND_STATUS}"; exit 1; }

# When

echo "STEP: When — retrieve ordered history"
echo "REQUEST_HEADERS: Accept: application/json"
echo "REQUEST_BODY: <empty>"
STATUS_CODE=$(curl -sS -o "$RESPONSE_BODY_FILE" -D "$RESPONSE_HEADERS_FILE" -w '%{http_code}' "$BASE_URL/history")
echo "RESPONSE_HEADERS:"
cat "$RESPONSE_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$RESPONSE_BODY_FILE"
echo "RESPONSE_STATUS: $STATUS_CODE"

# Then

echo "STEP: Then — verify message ordering is preserved"
[ "$STATUS_CODE" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${STATUS_CODE}"; exit 1; }
FIRST_LINE=$(grep -bo "$FIRST_MESSAGE" "$RESPONSE_BODY_FILE" | head -n 1 | cut -d: -f1)
SECOND_LINE=$(grep -bo "$SECOND_MESSAGE" "$RESPONSE_BODY_FILE" | head -n 1 | cut -d: -f1)
[ -n "$FIRST_LINE" ] || { echo "ASSERTION_FAILED: first message missing from history"; exit 1; }
[ -n "$SECOND_LINE" ] || { echo "ASSERTION_FAILED: second message missing from history"; exit 1; }
[ "$FIRST_LINE" -lt "$SECOND_LINE" ] || { echo "ASSERTION_FAILED: expected first message before second message"; exit 1; }

# Cleanup

echo "STEP: Cleanup — clear ordered history data"
curl -sS -o /dev/null -X POST "$BASE_URL/clear-history"

echo "CODEVALID_TEST_ASSERTION_OK:get_history_preserves_message_order"

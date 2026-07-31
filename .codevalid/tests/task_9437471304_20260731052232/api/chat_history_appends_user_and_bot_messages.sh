#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
POST_RESPONSE_BODY="/tmp/chat_history_post_response_${CASE_SUFFIX}.txt"
POST_RESPONSE_HEADERS="/tmp/chat_history_post_headers_${CASE_SUFFIX}.txt"
HISTORY_RESPONSE_BODY="/tmp/chat_history_history_response_${CASE_SUFFIX}.txt"
HISTORY_RESPONSE_HEADERS="/tmp/chat_history_history_headers_${CASE_SUFFIX}.txt"
CLEAR_RESPONSE_BODY="/tmp/chat_history_clear_response_${CASE_SUFFIX}.txt"
CLEAR_RESPONSE_HEADERS="/tmp/chat_history_clear_headers_${CASE_SUFFIX}.txt"
cleanup_files(){ rm -f "$POST_RESPONSE_BODY" "$POST_RESPONSE_HEADERS" "$HISTORY_RESPONSE_BODY" "$HISTORY_RESPONSE_HEADERS" "$CLEAR_RESPONSE_BODY" "$CLEAR_RESPONSE_HEADERS"; }
trap cleanup_files EXIT
# Given

echo "STEP: Given — clear chatbot history before validation"
echo "PREREQ: clear shared chat history"
CLEAR_CODE=$(curl -sS -o "$CLEAR_RESPONSE_BODY" -D "$CLEAR_RESPONSE_HEADERS" -w '%{http_code}' -X POST "$BASE_URL/history/clear")
echo "REQUEST_HEADERS: none"
echo "REQUEST_BODY: none"
echo "RESPONSE_HEADERS:"
cat "$CLEAR_RESPONSE_HEADERS"
echo "RESPONSE_BODY:"
cat "$CLEAR_RESPONSE_BODY"
echo "RESPONSE_STATUS: ${CLEAR_CODE}"
[ "$CLEAR_CODE" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 clearing history got ${CLEAR_CODE}"; exit 1; }
# When

echo "STEP: When — send greeting and fetch chat history"
REQUEST_BODY='{"message":"hello"}'
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: ${REQUEST_BODY}"
POST_CODE=$(curl -sS -o "$POST_RESPONSE_BODY" -D "$POST_RESPONSE_HEADERS" -w '%{http_code}' -X POST "$BASE_URL/chat" -H 'Content-Type: application/json' -d "$REQUEST_BODY")
echo "RESPONSE_HEADERS:"
cat "$POST_RESPONSE_HEADERS"
echo "RESPONSE_BODY:"
cat "$POST_RESPONSE_BODY"
echo "RESPONSE_STATUS: ${POST_CODE}"

echo "REQUEST_HEADERS: none"
echo "REQUEST_BODY: none"
HISTORY_CODE=$(curl -sS -o "$HISTORY_RESPONSE_BODY" -D "$HISTORY_RESPONSE_HEADERS" -w '%{http_code}' "$BASE_URL/history")
echo "RESPONSE_HEADERS:"
cat "$HISTORY_RESPONSE_HEADERS"
echo "RESPONSE_BODY:"
cat "$HISTORY_RESPONSE_BODY"
echo "RESPONSE_STATUS: ${HISTORY_CODE}"
# Then

echo "STEP: Then — history contains user and bot messages"
[ "$POST_CODE" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 from chat endpoint got ${POST_CODE}"; exit 1; }
[ "$HISTORY_CODE" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 from history endpoint got ${HISTORY_CODE}"; exit 1; }
grep -F '"sender":"user"' "$HISTORY_RESPONSE_BODY" >/dev/null || { echo "ASSERTION_FAILED: expected user sender in history response"; exit 1; }
grep -F '"text":"hello"' "$HISTORY_RESPONSE_BODY" >/dev/null || { echo "ASSERTION_FAILED: expected user text in history response"; exit 1; }
grep -F '"sender":"bot"' "$HISTORY_RESPONSE_BODY" >/dev/null || { echo "ASSERTION_FAILED: expected bot sender in history response"; exit 1; }
grep -F 'Hello! How can I help you today?' "$HISTORY_RESPONSE_BODY" >/dev/null || { echo "ASSERTION_FAILED: expected bot reply in history response"; exit 1; }
# Cleanup

echo "STEP: Cleanup — clear chatbot history after validation"
FINAL_CLEAR_CODE=$(curl -sS -o "$CLEAR_RESPONSE_BODY" -D "$CLEAR_RESPONSE_HEADERS" -w '%{http_code}' -X POST "$BASE_URL/history/clear")
[ "$FINAL_CLEAR_CODE" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 clearing history during cleanup got ${FINAL_CLEAR_CODE}"; exit 1; }
echo "CODEVALID_TEST_ASSERTION_OK:chat_history_appends_user_and_bot_messages"

#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_BODY="/tmp/input_validation_whitespace_only_message_response_${CASE_SUFFIX}.txt"
RESPONSE_HEADERS="/tmp/input_validation_whitespace_only_message_headers_${CASE_SUFFIX}.txt"
cleanup_files(){ rm -f "$RESPONSE_BODY" "$RESPONSE_HEADERS"; }
trap cleanup_files EXIT
# Given

echo "STEP: Given — chatbot API is reachable"
echo "PREREQ: no setup required for whitespace validation request"
# When

echo "STEP: When — send whitespace only message"
REQUEST_BODY='{"message":"    "}'
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: ${REQUEST_BODY}"
HTTP_CODE=$(curl -sS -o "$RESPONSE_BODY" -D "$RESPONSE_HEADERS" -w '%{http_code}' -X POST "$BASE_URL/chat" -H 'Content-Type: application/json' -d "$REQUEST_BODY")
echo "RESPONSE_HEADERS:"
cat "$RESPONSE_HEADERS"
echo "RESPONSE_BODY:"
cat "$RESPONSE_BODY"
echo "RESPONSE_STATUS: ${HTTP_CODE}"
# Then

echo "STEP: Then — API rejects whitespace only message"
[ "$HTTP_CODE" = "400" ] || { echo "ASSERTION_FAILED: expected HTTP 400 got ${HTTP_CODE}"; exit 1; }
grep -F 'Message cannot be empty' "$RESPONSE_BODY" >/dev/null || { echo "ASSERTION_FAILED: expected validation error in response body"; exit 1; }
# Cleanup

echo "STEP: Cleanup — no cleanup required"
echo "CODEVALID_TEST_ASSERTION_OK:input_validation_whitespace_only_message"

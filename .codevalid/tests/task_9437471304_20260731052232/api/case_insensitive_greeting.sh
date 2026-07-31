#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_BODY="/tmp/case_insensitive_greeting_response_${CASE_SUFFIX}.txt"
RESPONSE_HEADERS="/tmp/case_insensitive_greeting_headers_${CASE_SUFFIX}.txt"
cleanup_files(){ rm -f "$RESPONSE_BODY" "$RESPONSE_HEADERS"; }
trap cleanup_files EXIT
# Given

echo "STEP: Given — chatbot API is reachable"
echo "PREREQ: no setup required for case insensitive greeting request"
# When

echo "STEP: When — send mixed case greeting"
REQUEST_BODY='{"message":"HeLLo"}'
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: ${REQUEST_BODY}"
HTTP_CODE=$(curl -sS -o "$RESPONSE_BODY" -D "$RESPONSE_HEADERS" -w '%{http_code}' -X POST "$BASE_URL/chat" -H 'Content-Type: application/json' -d "$REQUEST_BODY")
echo "RESPONSE_HEADERS:"
cat "$RESPONSE_HEADERS"
echo "RESPONSE_BODY:"
cat "$RESPONSE_BODY"
echo "RESPONSE_STATUS: ${HTTP_CODE}"
# Then

echo "STEP: Then — chatbot normalizes case for greeting"
[ "$HTTP_CODE" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${HTTP_CODE}"; exit 1; }
grep -F 'Hello! How can I help you today?' "$RESPONSE_BODY" >/dev/null || { echo "ASSERTION_FAILED: expected normalized greeting response"; exit 1; }
# Cleanup

echo "STEP: Cleanup — no cleanup required"
echo "CODEVALID_TEST_ASSERTION_OK:case_insensitive_greeting"

#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"

RESPONSE_BODY_FILE="/tmp/missing_index_html_file_response_body_${CASE_SUFFIX}.txt"
RESPONSE_HEADERS_FILE="/tmp/missing_index_html_file_response_headers_${CASE_SUFFIX}.txt"

cleanup_files() {
  rm -f "$RESPONSE_BODY_FILE" "$RESPONSE_HEADERS_FILE"
}
trap cleanup_files EXIT

# Given
echo "STEP: Given — prepare to validate missing index.html behavior"
echo "PREREQ: using BASE_URL=$BASE_URL"

# When
echo "STEP: When — request the index route while index.html is unavailable"
echo "REQUEST_HEADERS: Accept: text/html"
echo "REQUEST_BODY: <empty>"

HTTP_STATUS=$(curl -sS -D "$RESPONSE_HEADERS_FILE" -o "$RESPONSE_BODY_FILE" -w '%{http_code}' \
  -H 'Accept: text/html' \
  "$BASE_URL/")

echo "RESPONSE_HEADERS:"
cat "$RESPONSE_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$RESPONSE_BODY_FILE"
echo "RESPONSE_STATUS: $HTTP_STATUS"

# Then
echo "STEP: Then — verify the service behavior for missing index.html"
[ "$HTTP_STATUS" = "500" ] || { echo "ASSERTION_FAILED: expected HTTP 500 got ${HTTP_STATUS}"; exit 1; }

# Cleanup
echo "STEP: Cleanup — no cleanup required"

echo "CODEVALID_TEST_ASSERTION_OK:missing_index_html_file"

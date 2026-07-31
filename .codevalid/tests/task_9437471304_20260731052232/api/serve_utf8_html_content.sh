#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"

RESPONSE_BODY_FILE="/tmp/serve_utf8_html_content_response_body_${CASE_SUFFIX}.txt"
RESPONSE_HEADERS_FILE="/tmp/serve_utf8_html_content_response_headers_${CASE_SUFFIX}.txt"

cleanup_files() {
  rm -f "$RESPONSE_BODY_FILE" "$RESPONSE_HEADERS_FILE"
}
trap cleanup_files EXIT

# Given
echo "STEP: Given — prepare to validate UTF-8 HTML response"
echo "PREREQ: using BASE_URL=$BASE_URL"

# When
echo "STEP: When — request the HTML page containing UTF-8 content"
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
echo "STEP: Then — verify UTF-8 content is preserved"
[ "$HTTP_STATUS" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${HTTP_STATUS}"; exit 1; }
grep -iq 'charset=utf-8' "$RESPONSE_HEADERS_FILE" || { echo "ASSERTION_FAILED: expected UTF-8 charset in headers"; exit 1; }
python3 - "$RESPONSE_BODY_FILE" <<'PY'
import pathlib
import sys
path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding='utf-8')
if '\ufffd' in text:
    print('ASSERTION_FAILED: found replacement character indicating encoding corruption')
    raise SystemExit(1)
print('UTF8_VALIDATION_OK')
PY

# Cleanup
echo "STEP: Cleanup — no cleanup required"

echo "CODEVALID_TEST_ASSERTION_OK:serve_utf8_html_content"

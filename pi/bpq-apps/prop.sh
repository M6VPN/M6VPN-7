#!/usr/bin/env bash
set -u

CACHE="/home/pi/bpq-cache/prop.txt"

crlf() { printf '%s\r\n' "$*"; }

CALL="UNKNOWN"
if IFS= read -r -t 1 CALL_IN; then
    CALL="${CALL_IN//$'\r'/}"
    CALL="${CALL//$'\n'/}"
    CALL="$(printf '%s' "$CALL" | tr -cd 'A-Za-z0-9-')"
fi
[ -n "$CALL" ] || CALL="UNKNOWN"

crlf ""
crlf "Caller: $CALL"
crlf ""

if [ -s "$CACHE" ]; then
    # Convert LF to CRLF for packet terminals.
    sed 's/$/\r/' "$CACHE"
else
    crlf "PROP cache not available yet."
    crlf "Try again after the next cache update."
fi

crlf ""
sleep 1

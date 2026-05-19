#!/usr/bin/env bash
# M6VPN-7 - Developed by dgm (dgm@tuta.com)
# M6VPN-7/pi/bpq-apps/prop.sh
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CACHE="/home/pi/bpq-cache/prop.txt"

# shellcheck source=pi/bpq-apps/common.sh
source "$SCRIPT_DIR/common.sh"

cache_age() {
	local cache_mtime=""
	local now=""
	local age=""

	cache_mtime="$(stat -c '%Y' "$CACHE" 2>/dev/null || true)"
	now="$(date +%s)"

	if [ -n "$cache_mtime" ]; then
		age="$(( (now - cache_mtime) / 60 ))"
		crlf "Cache age: $age minutes"
		crlf ""
	fi
}

CALL="$(read_caller)"

crlf ""
crlf "M6VPN-7 PROP"
crlf ""
crlf "Caller: $CALL"
crlf ""

if [ -s "$CACHE" ]; then
	cache_age
	while IFS= read -r line || [ -n "$line" ]; do
		crlf "$line"
	done < "$CACHE"
else
	crlf "PROP cache not available yet."
	crlf "Try again after the next cache update."
fi

crlf ""
sleep 1

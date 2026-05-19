#!/usr/bin/env bash
# M6VPN-7 - Developed by dgm (dgm@tuta.com)
# M6VPN-7/pi/bpq-apps/common.sh

crlf() {
	printf '%s\r\n' "$*"
}


read_caller() {
	local call="UNKNOWN"
	local call_in=""

	if IFS= read -r -t 1 call_in; then
		call="${call_in//$'\r'/}"
		call="${call//$'\n'/}"
		call="$(printf '%s' "$call" | tr -cd 'A-Za-z0-9-')"
	fi

	if [ -z "$call" ]; then
		call="UNKNOWN"
	fi

	printf '%s' "$call"
}

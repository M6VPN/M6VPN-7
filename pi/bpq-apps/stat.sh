#!/usr/bin/env bash
# M6VPN-7 - Developed by dgm (dgm@tuta.com)
# M6VPN-7/pi/bpq-apps/stat.sh
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=pi/bpq-apps/common.sh
source "$SCRIPT_DIR/common.sh"

CALL="$(read_caller)"


last_match() {
	local pattern="$1"
	shift

	grep -h "$pattern" "$@" 2>/dev/null | tail -n 1 | sed 's/^[[:space:]]*//'
}


port_state() {
	local port="$1"

	if ss -ltn 2>/dev/null | awk '{print $4}' | grep -q ":${port}$"; then
		printf 'listening'
	else
		printf 'closed'
	fi
}


proc_state() {
	if pgrep -f "$1" >/dev/null 2>&1; then
		printf 'running'
	else
		printf 'not running'
	fi
}


svc_state() {
	local state=""

	state="$(systemctl is-active "$1" 2>/dev/null || true)"

	if [ -n "$state" ]; then
		printf '%s' "$state"
	else
		printf 'unknown'
	fi
}


UPTIME="$(uptime -p 2>/dev/null | sed 's/^up //')"
LOAD="$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null)"
DISK="$(df -h /home/pi 2>/dev/null | awk 'NR==2 {print $5 " used, " $4 " free"}')"
MEM="$(free -m 2>/dev/null | awk '/Mem:/ {printf "%d/%d MB used", $3, $2}')"

DW_SERVICE="$(svc_state direwolf-ic2350.service)"
BPQ_SERVICE="$(svc_state linbpq.service)"
DW_PROC="$(proc_state '/usr/local/bin/direwolf|/usr/bin/direwolf')"
BPQ_PROC="$(proc_state '/home/pi/linbpq/linbpq')"
AGW_PORT="$(port_state 8000)"
KISS_PORT="$(port_state 8001)"

LAST_GB7CNR="$(last_match 'GB7CNR' /home/pi/linbpq/logLatest_BBS.txt /home/pi/linbpq/Logs/* 2>/dev/null)"
LAST_DW="$(last_match 'audio level\|CONNECTED\|KISS client\|ERROR\|audio device' /home/pi/direwolf.log 2>/dev/null)"

crlf ""
crlf "M6VPN-7 NCLCC STAT"
crlf "------------------"
crlf "Caller:     $CALL"
crlf "OS:         GNU/Linux (Armbian) armv7l"
crlf "Uptime:     ${UPTIME:-unknown}"
crlf "Load:       ${LOAD:-unknown}"
crlf "Memory:     ${MEM:-unknown}"
crlf "Disk /home: ${DISK:-unknown}"
crlf ""
crlf "Radio/node:"
crlf " RF:        144.9375 MHz FM 1200bd AX.25"
crlf " Node:      M6VPN-7"
crlf " BBS:       M6VPN-1 #18.GBR.EURO"
crlf " Forward:   GB7CNR-1 #17.GBR.EURO"
crlf ""
crlf "Services:"
crlf " Dire Wolf: $DW_SERVICE ($DW_PROC)"
crlf " LinBPQ:    $BPQ_SERVICE ($BPQ_PROC)"
crlf " AGW 8000:  $AGW_PORT"
crlf " KISS 8001: $KISS_PORT"
crlf ""

if [ -n "${LAST_GB7CNR:-}" ]; then
	crlf "Last GB7CNR log:"
	crlf "$LAST_GB7CNR"
	crlf ""
fi

if [ -n "${LAST_DW:-}" ]; then
	crlf "Last Dire Wolf log:"
	crlf "$LAST_DW"
	crlf ""
fi

crlf "73 de M6VPN"
crlf ""
sleep 1

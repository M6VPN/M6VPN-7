#!/usr/bin/env bash
# M6VPN-7 - Developed by dgm (dgm@tuta.com)
# M6VPN-7/pi/bpq-apps/zork.sh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=pi/bpq-apps/common.sh
source "$SCRIPT_DIR/common.sh"

GAME="/home/pi/zork/zork1.z5"
CALL="$(read_caller)"
INTERPRETER=""

crlf ""
crlf "M6VPN ZORK gateway"
crlf "Caller: $CALL"
crlf "Commands: LOOK N S E W TAKE INVENTORY QUIT"
crlf "Keep sessions short: 1200 baud packet."
crlf ""

if [ ! -f "$GAME" ]; then
	crlf "Zork game file not found:"
	crlf "$GAME"
	crlf ""
	crlf "Install a legitimate Z-machine game file."
	exit 0
fi

if command -v dfrotz >/dev/null 2>&1; then
	INTERPRETER="$(command -v dfrotz)"
elif command -v frotz >/dev/null 2>&1; then
	INTERPRETER="$(command -v frotz)"
elif [ -x /usr/games/dfrotz ]; then
	INTERPRETER="/usr/games/dfrotz"
fi

if [ -z "$INTERPRETER" ]; then
	crlf "No frotz or dfrotz interpreter found."
	exit 1
fi

exec "$INTERPRETER" "$GAME"

#!/usr/bin/env bash
# M6VPN-7 - Developed by M6VPN (M6VPN@tuta.com)
# M6VPN-7/pi/bpq-apps/wx.sh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=pi/bpq-apps/common.sh
source "$SCRIPT_DIR/common.sh"

CALL="$(read_caller)"
WX="$(curl -fsS --max-time 8 'https://wttr.in/Newcastle-upon-Tyne?format=3' 2>/dev/null | LC_ALL=C tr -cd '\11\12\15\40-\176' | sed 's/[[:space:]][[:space:]]*/ /g' || true)"

crlf ""
crlf "M6VPN-7 WX"
crlf "Caller: $CALL"
crlf ""

if [ -n "$WX" ]; then
	crlf "$WX"
else
	crlf "WX source unavailable."
fi

crlf ""
crlf "73 de M6VPN"
crlf ""

#!/usr/bin/env bash
# M6VPN-7 - Developed by dgm (dgm@tuta.com)
# M6VPN-7/pi/bpq-apps/help.sh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=pi/bpq-apps/common.sh
source "$SCRIPT_DIR/common.sh"

CALL="$(read_caller)"

crlf ""
crlf "M6VPN-7 HELP"
crlf "Caller: $CALL"
crlf ""
crlf "Node: M6VPN-7 NCLCC"
crlf "BBS:  M6VPN-1 #18.GBR.EURO"
crlf "RF:   144.9375 MHz FM 1200bd AX.25"
crlf "QTH:  Newcastle city centre, IO94EX"
crlf ""
crlf "Commands:"
crlf " BBS   - Mailbox / BBS"
crlf " CHAT  - LinBPQ chat"
crlf " WX    - Current Newcastle weather"
crlf " PROP  - Cached NOAA/SWPC space weather"
crlf " STAT  - Node status"
crlf " ZORK  - Z-machine game"
crlf " HELP  - This menu"
crlf ""
crlf "Node commands: INFO PORTS USERS BYE"
crlf ""
crlf "73 de M6VPN"
crlf ""

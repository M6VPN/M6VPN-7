#!/usr/bin/env bash
set -euo pipefail

# LinBPQ normally sends caller callsign as first line.
read -r CALL || CALL="UNKNOWN"
CALL="$(printf '%s' "$CALL" | tr -cd 'A-Za-z0-9-')"

#printf "\r\nM6VPN-7 WX 144.9375 MHz - Newcastle / IO94EX\r\n"
#printf "Caller: %s\r\n" "$CALL"
#printf "Generated: %s UTC\r\n\r\n" "$(date -u '+%Y-%m-%d %H:%M')"

# RF-friendly one-line weather. Change location if desired.
WX="$(curl -fsS --max-time 8 'https://wttr.in/Newcastle-upon-Tyne?format=3' 2>/dev/null || true)"

if [ -n "$WX" ]; then
    printf "%s\r\n\r\n" "$WX"
else
    printf "WX source unavailable.\r\n\r\n"
fi

# printf "Station: M6VPN-7 node / M6VPN-1 BBS\r\n"
# printf "Freq: 144.9375 MHz FM 1200bd AX.25\r\n"
printf "\r\n73.\r\n"

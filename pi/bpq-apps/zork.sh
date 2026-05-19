#!/usr/bin/env bash
set -euo pipefail

read -r CALL || CALL="UNKNOWN"
CALL="$(printf '%s' "$CALL" | tr -cd 'A-Za-z0-9-')"

GAME="/home/pi/zork/zork1.z5"

printf "\r\nM6VPN ZORK gateway\r\n"
printf "Caller: %s\r\n" "$CALL"
printf "Commands usually include: LOOK, N, S, E, W, TAKE, INVENTORY, QUIT\r\n"
printf "Keep sessions short: this is 1200 baud packet.\r\n\r\n"

if [ ! -f "$GAME" ]; then
    printf "Zork game file not found:\r\n%s\r\n\r\n" "$GAME"
    printf "Install a legitimate Z-machine .z3/.z5/.dat game file and try again.\r\n"
    exit 0
fi

exec /usr/games/dfrotz "$GAME"

#if command -v dfrotz >/dev/null 2>&1; then
#    exec dfrotz "$GAME"
#elif command -v frotz >/dev/null 2>&1; then
#    exec frotz "$GAME"
#else
#    printf "No frotz/dfrotz interpreter found.\r\n"
#    exit 1
#fi

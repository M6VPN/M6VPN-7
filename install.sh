#!/usr/bin/env bash
# M6VPN-7 - Developed by dgm (dgm@tuta.com)
# M6VPN-7/install.sh
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PI_SRC="$REPO_DIR/pi"
SYSTEMD_SRC="$REPO_DIR/systemd"
PI_DEST="/home/pi"
SYSTEMD_DEST="/etc/systemd/system"
BPQ_CFG="$PI_DEST/linbpq/bpq32.cfg"

SOCKET_UNITS=(
	"bpq-help.socket"
	"bpq-prop.socket"
	"bpq-stat.socket"
	"bpq-wx.socket"
	"bpq-zork.socket"
)

SERVICE_UNITS=(
	"direwolf-ic2350.service"
	"linbpq.service"
)

TIMER_UNITS=(
	"prop-cache-update.timer"
)


copy_pi_tree() {
	local patch_bpq="${1:-no}"

	require_dir "$PI_SRC"
	require_dir "$PI_DEST"

	if [ "$patch_bpq" = "yes" ]; then
		copy_pi_tree_without_bpq
		patch_bpq32_cfg
	else
		cp -a "$PI_SRC/." "$PI_DEST/"
	fi

	chown -R pi:pi "$PI_DEST/bpq-apps" "$PI_DEST/bpq-cache" "$PI_DEST/linbpq" "$PI_DEST/direwolf.ic2350.conf"
	chmod +x "$PI_DEST"/bpq-apps/*.sh "$PI_DEST"/bpq-apps/*.py 2>/dev/null || true
	printf 'updated %s from %s\n' "$PI_DEST" "$PI_SRC"
}


copy_pi_tree_without_bpq() {
	mkdir -p "$PI_DEST/bpq-apps" "$PI_DEST/bpq-cache" "$PI_DEST/linbpq/HTML"
	cp -a "$PI_SRC/bpq-apps/." "$PI_DEST/bpq-apps/"
	cp -a "$PI_SRC/bpq-cache/." "$PI_DEST/bpq-cache/"
	cp -a "$PI_SRC/direwolf.ic2350.conf" "$PI_DEST/"
	cp -a "$PI_SRC/linbpq/HTML/." "$PI_DEST/linbpq/HTML/"
}


install_systemd_units() {
	update_systemd_units
	systemctl enable --now "${SOCKET_UNITS[@]}" "${TIMER_UNITS[@]}"
	systemctl enable "${SERVICE_UNITS[@]}"
	printf 'enabled systemd units\n'
}


main() {
	local command="${1:-menu}"

	case "$command" in
		pi)
			require_root
			copy_pi_tree "${2:-no}"
			;;
		pi-patch)
			require_root
			copy_pi_tree "yes"
			;;
		systemd-update)
			require_root
			update_systemd_units
			;;
		systemd-install)
			require_root
			install_systemd_units
			;;
		menu)
			menu
			;;
		help|-h|--help)
			usage
			;;
		*)
			usage
			exit 1
			;;
	esac
}


menu() {
	local choice=""
	local patch_bpq=""

	printf '\nM6VPN-7 installer\n\n'
	printf '1) Copy ./pi/ to /home/pi/\n'
	printf '2) Update systemd unit files and reload\n'
	printf '3) Install and enable new systemd services/sockets\n'
	printf '\nSelect option: '
	read -r choice

	case "$choice" in
		1)
			require_root
			printf 'Patch live bpq32.cfg instead of replacing it? [y/N]: '
			read -r patch_bpq

			if [ "$patch_bpq" = "y" ] || [ "$patch_bpq" = "Y" ]; then
				copy_pi_tree "yes"
			else
				copy_pi_tree "no"
			fi
			;;
		2)
			require_root
			update_systemd_units
			;;
		3)
			require_root
			install_systemd_units
			;;
		*)
			printf 'invalid option\n' >&2
			exit 1
			;;
	esac
}


patch_bpq32_cfg() {
	require_file "$BPQ_CFG"

	if ! grep -q '63034' "$BPQ_CFG"; then
		sed -i 's/CMDPORT 63030 63031 63032 63033/CMDPORT 63030 63031 63032 63033 63034/' "$BPQ_CFG"
	fi

	if ! grep -q '^APPLICATION 7,HELP,C 10 HOST 4 S' "$BPQ_CFG"; then
		printf '\nAPPLICATION 7,HELP,C 10 HOST 4 S\n' >> "$BPQ_CFG"
	fi

	sed -i 's/BBS CHAT WX PROP STAT CONNECT/BBS CHAT WX PROP STAT HELP CONNECT/' "$BPQ_CFG"
	sed -i 's/BBS CHAT WX PROP STAT INFO/BBS CHAT WX PROP STAT HELP INFO/' "$BPQ_CFG"
	printf 'patched %s\n' "$BPQ_CFG"
}


require_dir() {
	local path="$1"

	if [ ! -d "$path" ]; then
		printf 'missing directory: %s\n' "$path" >&2
		exit 1
	fi
}


require_file() {
	local path="$1"

	if [ ! -f "$path" ]; then
		printf 'missing file: %s\n' "$path" >&2
		exit 1
	fi
}


require_root() {
	if [ "$(id -u)" -ne 0 ]; then
		printf 'run this script as root on the live system\n' >&2
		exit 1
	fi
}


update_systemd_units() {
	require_dir "$SYSTEMD_SRC"
	require_dir "$SYSTEMD_DEST"

	cp -a "$SYSTEMD_SRC/." "$SYSTEMD_DEST/"
	systemctl daemon-reload
	printf 'updated %s from %s and reloaded systemd\n' "$SYSTEMD_DEST" "$SYSTEMD_SRC"
}


usage() {
	printf 'usage: %s [menu|pi|pi-patch|systemd-update|systemd-install|help]\n' "$0"
	printf '\n'
	printf 'commands:\n'
	printf '  menu             interactive menu\n'
	printf '  pi               copy ./pi/ to /home/pi/\n'
	printf '  pi yes           copy ./pi/ except bpq32.cfg, then patch live bpq32.cfg\n'
	printf '  pi-patch         same as: pi yes\n'
	printf '  systemd-update   copy systemd/* to /etc/systemd/system/ and reload\n'
	printf '  systemd-install  update systemd units, then enable services/sockets\n'
}


main "$@"

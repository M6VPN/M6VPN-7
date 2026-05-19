// M6VPN-7 - Developed by M6VPN (M6VPN@tuta.com)
// M6VPN-7/pi/linbpq/HTML/m6vpn-ui.js

(function () {
	function ready(fn) {
		if (document.readyState === 'loading') {
			document.addEventListener('DOMContentLoaded', fn);
		} else {
			fn();
		}
	}

	function tagNavigationTables() {
		var tables = document.getElementsByTagName('table');
		var i;

		for (i = 0; i < tables.length; i += 1) {
			if (tables[i].getElementsByTagName('a').length >= 2) {
				tables[i].className = (tables[i].className ? tables[i].className + ' ' : '') + 'bpq-nav';
				return;
			}
		}
	}

	ready(function () {
		document.body.className = (document.body.className ? document.body.className + ' ' : '') + 'm6vpn-ready';
		tagNavigationTables();
	});
}());

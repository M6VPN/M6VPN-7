#!/usr/bin/env python3
# M6VPN-7 - Developed by M6VPN (M6VPN@tuta.com)
# M6VPN-7/pi/bpq-apps/update-prop-cache.py
import json
import os
import urllib.request

from datetime import datetime, timezone


CACHE = '/home/pi/bpq-cache/prop.txt'
TMP   = CACHE + '.tmp'
URLS  = {
	'kp'                : 'https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json',
	'kp_forecast'       : 'https://services.swpc.noaa.gov/products/noaa-planetary-k-index-forecast.json',
	'solar_wind_mag'    : 'https://services.swpc.noaa.gov/products/solar-wind/mag-1-day.json',
	'solar_wind_plasma' : 'https://services.swpc.noaa.gov/products/solar-wind/plasma-1-day.json',
}


def fetch_json(url: str, timeout: int = 12) -> object:
	'''
	Fetch JSON data from a NOAA/SWPC endpoint.

	:param url: The NOAA/SWPC JSON URL
	:param timeout: The HTTP timeout in seconds
	'''

	req = urllib.request.Request(url, headers={'User-Agent': 'M6VPN-LinBPQ-PROP/1.0'})

	with urllib.request.urlopen(req, timeout=timeout) as response:
		return json.loads(response.read().decode('utf-8', errors='replace'))


def fmt(value: float | None, unit: str = '', ndp: int = 1) -> str:
	'''
	Format a numeric value for packet output.

	:param value: The numeric value to format
	:param unit: The unit suffix to append
	:param ndp: The number of decimal places
	'''

	if value is None:
		return 'n/a'

	return f'{value:.{ndp}f}{unit}'


def hf_note(kp: float | None, bz: float | None) -> str:
	'''
	Return a short HF propagation note.

	:param kp: The latest Kp value
	:param bz: The latest Bz value
	'''

	if kp is not None and kp >= 5:
		return 'HF: disturbed; expect absorption/fading, especially polar/high-lat paths.'

	if bz is not None and bz < -5:
		return 'HF: southward Bz; geomagnetic activity may increase.'

	return 'HF: no major storm flag from Kp/Bz.'


def kp_meaning(kp: float | None) -> str:
	'''
	Return a short Kp condition label.

	:param kp: The latest Kp value
	'''

	if kp is None:
		return 'unknown'

	if kp < 3:
		return 'quiet'

	if kp < 5:
		return 'unsettled/active'

	if kp < 6:
		return 'minor storm'

	if kp < 7:
		return 'moderate storm'

	if kp < 8:
		return 'strong storm'

	return 'severe/extreme storm'


def latest_data_row(rows: object) -> object | None:
	'''
	Return the latest data row from SWPC list-style JSON.

	:param rows: The decoded SWPC JSON rows
	'''

	if not isinstance(rows, list):
		return None

	for row in reversed(rows):
		if isinstance(row, dict):
			return row

		if isinstance(row, list) and row and not str(row[0]).lower().startswith('time'):
			return row

	return None


def main():
	'''Update the cached packet-friendly propagation report.'''

	lines    = []
	now      = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')
	forecast = []

	kp       = None
	kp_time  = 'n/a'
	bz       = None
	bt       = None
	sw_speed = None
	density  = None

	try:
		kp_rows = fetch_json(URLS['kp'])
		row     = latest_data_row(kp_rows)

		if isinstance(row, dict):
			kp_time = str(row.get('time_tag', 'n/a'))
			kp      = safe_float(row.get('Kp', row.get('kp')))
		elif isinstance(row, list):
			kp_time = str(row[0])
			kp      = safe_float(row[1])
	except Exception as error:
		lines.append(f'Kp fetch error: {error}')

	try:
		fc_rows = fetch_json(URLS['kp_forecast'])

		if isinstance(fc_rows, list):
			for row in fc_rows[-6:]:
				if isinstance(row, dict):
					t     = row.get('time_tag', 'n/a')
					k     = row.get('kp', row.get('Kp', 'n/a'))
					obs   = row.get('observed', '')
					scale = row.get('noaa_scale') or ''
					forecast.append(f'{t} Kp={k} {obs} {scale}'.strip())
				elif isinstance(row, list) and len(row) >= 2 and not str(row[0]).lower().startswith('time'):
					forecast.append(' '.join(str(item) for item in row[:4]))
	except Exception as error:
		lines.append(f'Kp forecast fetch error: {error}')

	try:
		mag_rows = fetch_json(URLS['solar_wind_mag'])
		row      = latest_data_row(mag_rows)

		if isinstance(row, list):
			bz = safe_float(row[3]) if len(row) > 3 else None
			bt = safe_float(row[6]) if len(row) > 6 else None
	except Exception as error:
		lines.append(f'Solar wind mag fetch error: {error}')

	try:
		plasma_rows = fetch_json(URLS['solar_wind_plasma'])
		row         = latest_data_row(plasma_rows)

		if isinstance(row, list):
			density  = safe_float(row[1]) if len(row) > 1 else None
			sw_speed = safe_float(row[2]) if len(row) > 2 else None
	except Exception as error:
		lines.append(f'Solar wind plasma fetch error: {error}')

	out = [
		'M6VPN-7 PROP - cached space weather',
		'-----------------------------------',
		f'Updated: {now}',
		'',
		f'Kp:       {fmt(kp, "", 1)}  ({kp_meaning(kp)})',
		f'Kp time:  {kp_time}',
		f'Bz:       {fmt(bz, " nT", 1)}',
		f'Bt:       {fmt(bt, " nT", 1)}',
		f'SW speed: {fmt(sw_speed, " km/s", 0)}',
		f'Density:  {fmt(density, " p/cc", 1)}',
		'',
		hf_note(kp, bz),
		vhf_note(kp),
		'',
	]

	if forecast:
		out.append('Kp forecast, latest rows:')

		for item in forecast[-3:]:
			out.append('  ' + item)

		out.append('')

	if lines:
		out.append('Warnings:')

		for line in lines:
			out.append('  ' + line)

		out.append('')

	out.append('Source: NOAA/SWPC cached JSON data.')
	out.append('73 de M6VPN')

	with open(TMP, 'w', encoding='utf-8') as cache_file:
		cache_file.write('\n'.join(out) + '\n')

	os.replace(TMP, CACHE)


def safe_float(value: object) -> float | None:
	'''
	Convert a value to float where possible.

	:param value: The value to convert
	'''

	try:
		return float(value)
	except Exception:
		return None


def vhf_note(kp: float | None) -> str:
	'''
	Return a short VHF propagation note.

	:param kp: The latest Kp value
	'''

	if kp is None:
		return '2m: check locally.'

	if kp >= 5:
		return '2m: auroral effects possible; packet may be distorted on auroral paths.'

	return '2m: normal local line-of-sight conditions likely.'



if __name__ == '__main__':
	main()

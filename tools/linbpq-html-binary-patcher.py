#!/usr/bin/env python3
# M6VPN-7 - Developed by M6VPN (M6VPN@tuta.com)
# M6VPN-7/tools/linbpq-html-binary-patcher.py
import argparse
import json
import os
import shutil
import sys

from datetime import datetime


STYLE_BODY = b'*{color:#d9ffe8}body{background:#050807}'
STYLE_TABLE = b'td,th{color:#d9ffe8}table{background:#0b1210}'


def add_rule(rules: list[dict[str, object]], name: str, find: bytes, replace: bytes):
	'''
	Add one equal-or-shorter binary replacement rule.

	:param rules: The mutable rule list
	:param name: The rule name
	:param find: The bytes to search for
	:param replace: The replacement bytes
	'''

	rules.append({
		'name'    : name,
		'find'    : find,
		'replace' : pad_replacement(find, replace),
	})


def apply_patch_bytes(data: bytes, rules: list[dict[str, object]]) -> tuple[bytes, list[dict[str, int]]]:
	'''
	Apply all binary replacement rules to a byte string.

	:param data: The source binary bytes
	:param rules: Replacement rules
	'''

	results = []
	patched = data

	for rule in rules:
		find    = rule['find']
		replace = rule['replace']
		count   = patched.count(find)

		if count:
			patched = patched.replace(find, replace)

		results.append({
			'name'  : rule['name'],
			'count' : count,
		})

	return patched, results


def backup_path(path: str) -> str:
	'''
	Return a timestamped backup path for a binary.

	:param path: The original binary path
	'''

	stamp = datetime.utcnow().strftime('%Y%m%d%H%M%S')
	return f'{path}.bak-{stamp}'


def build_default_rules() -> list[dict[str, object]]:
	'''Build the default LinBPQ hard-coded HTML patch rules.'''

	rules = []

	add_rule(rules, 'double-quoted body background', b'background="/background.jpg"', b'bgcolor=#050807 text=#d9ffe8')
	add_rule(rules, 'single-quoted body background', b"background='/background.jpg'", b'bgcolor=#050807 text=#d9ffe8')
	add_rule(rules, 'unquoted body background', b'background=/background.jpg', b'bgcolor=#050807 text=#fff')
	add_rule(rules, 'aprs clouds background', b'background="Images/clouds.jpg"', b'bgcolor=#050807 text=#d9ffe8')
	add_rule(rules, 'upgrade old double body style', b'style="background:#050807"  ', b'bgcolor=#050807 text=#d9ffe8')
	add_rule(rules, 'upgrade old single body style', b"style='background:#050807'  ", b'bgcolor=#050807 text=#d9ffe8')
	add_rule(rules, 'upgrade old unquoted body style', b'style=background:#050807  ', b'bgcolor=#050807 text=#fff')
	add_rule(rules, 'upgrade old aprs body style', b'style="background:#050807"    ', b'bgcolor=#050807 text=#d9ffe8')

	add_rule(rules, 'table white unquoted', b'bgcolor=white', b'bgcolor=black')
	add_rule(rules, 'table white double quoted', b'bgcolor="white"', b'bgcolor="black"')
	add_rule(rules, 'table white single quoted hex', b"bgcolor='ffffff'", b"bgcolor='black'")
	add_rule(rules, 'table cream double quoted', b'bgcolor="#FFFFCC"', b'bgcolor="#101a17"')
	add_rule(rules, 'table cream unquoted', b'bgcolor=#FFFFCC', b'bgcolor=#101a17')

	add_rule(rules, 'panel white css lowercase', b'background-color: #ffffff', b'background-color: #050807')
	add_rule(rules, 'panel peach css uppercase', b'background-color: #FFCC99', b'background-color: #101a17')
	add_rule(rules, 'white hex color', b'#FFFFFF', b'#050807')
	add_rule(rules, 'yellow hex color', b'#FFFF00', b'#ffc857')
	add_rule(rules, 'green sent hex color', b'#98FFA0', b'#39ff88')

	add_rule(rules, 'button active css body', b'input.btn:active {background:black;color:white;} ', STYLE_BODY)
	add_rule(rules, 'submit active css table', b'submit.btn:active {background:black;color:white;} ', STYLE_TABLE)
	add_rule(rules, 'upgrade old button css body', b'body{background:#050807;color:#d9ffe8;}          ', STYLE_BODY)
	add_rule(rules, 'upgrade old submit css table', b'table{background:#0b1210;color:#d9ffe8;}          ', STYLE_TABLE)
	add_rule(rules, 'webproc drop button border', b'.dropbtn {position: relative; border: 1px solid black;padding:1px;}', b'.dropbtn {position: relative; border: 1px solid #3f8;padding:1px;}')
	add_rule(rules, 'webproc dropdown background', b'background-color: #f1f1f1', b'background-color: #101a17')
	add_rule(rules, 'webproc dropdown background short', b'background-color: #ccc', b'background-color: #111')
	add_rule(rules, 'webproc hover background', b'background-color: #dddfff', b'background-color: #21483d')
	add_rule(rules, 'webproc dropbtn hover', b'background-color: #ddd', b'background-color: #111')

	add_rule(rules, 'default main white panel crlf', b'#main{width:700px;position:absolute;left:0px;border:2px solid;background-color: #ffffff;}\r\n', b'#main{width:700px;position:absolute;left:0px;border:2px solid;background-color: #050807;}\r\n')
	add_rule(rules, 'default main white panel', b'#main{width:700px;position:absolute;left:0px;border:2px solid;background-color: #ffffff;}', b'#main{width:700px;position:absolute;left:0px;border:2px solid;background-color: #050807;}')

	return rules


def fail(message: str, code: int = 1) -> int:
	'''
	Print an error and return an exit code.

	:param message: The error message
	:param code: The exit code
	'''

	print(f'error: {message}', file=sys.stderr)
	return code


def load_custom_rules(path: str) -> list[dict[str, object]]:
	'''
	Load extra replacement rules from a JSON file.

	:param path: The JSON rule file path
	'''

	with open(path, 'r', encoding='utf-8') as rule_file:
		raw_rules = json.load(rule_file)

	rules = []

	for idx, raw_rule in enumerate(raw_rules, 1):
		name = raw_rule.get('name', f'custom rule {idx}')
		find = raw_rule['find'].encode('utf-8')
		replace = raw_rule['replace'].encode('utf-8')
		add_rule(rules, name, find, replace)

	return rules


def main() -> int:
	'''Main CLI entrypoint.'''

	args = parse_args()
	rules = build_default_rules()

	if args.rules:
		rules.extend(load_custom_rules(args.rules))

	try:
		validate_rules(rules)
	except ValueError as error:
		return fail(str(error))

	data = read_binary(args.binary)
	patched, results = apply_patch_bytes(data, rules)
	changed = patched != data

	report_results(results, changed)

	if args.dry_run:
		return 0

	if not changed:
		print('no changes written')
		return 0

	target = args.output or args.binary

	if args.output:
		write_binary(target, patched)
	else:
		if args.backup:
			backup = backup_path(args.binary)
			shutil.copy2(args.binary, backup)
			print(f'backup: {backup}')

		write_binary(target, patched)

	print(f'patched: {target}')
	return 0


def pad_replacement(find: bytes, replace: bytes) -> bytes:
	'''
	Pad a replacement to exactly match the searched byte length.

	:param find: The bytes to search for
	:param replace: The replacement bytes
	'''

	if len(replace) > len(find):
		raise ValueError(f'replacement is longer than search bytes: {replace!r}')

	return replace + (b' ' * (len(find) - len(replace)))


def parse_args() -> argparse.Namespace:
	'''Parse CLI arguments.'''

	parser = argparse.ArgumentParser(description='Patch LinBPQ hard-coded web HTML strings inside a compiled binary.')
	parser.add_argument('binary', help='Path to the compiled LinBPQ/BPQ32 binary to patch')
	parser.add_argument('-n', '--dry-run', action='store_true', help='Scan and report matching rules without writing')
	parser.add_argument('-o', '--output', help='Write patched bytes to this output path instead of replacing the input')
	parser.add_argument('-r', '--rules', help='Optional JSON file with extra equal-or-shorter replacement rules')
	parser.add_argument('--no-backup', action='store_false', dest='backup', help='Do not create a backup when patching in place')
	parser.set_defaults(backup=True)

	return parser.parse_args()


def read_binary(path: str) -> bytes:
	'''
	Read a binary file.

	:param path: The binary file path
	'''

	with open(path, 'rb') as binary_file:
		return binary_file.read()


def report_results(results: list[dict[str, int]], changed: bool):
	'''
	Print patch match results.

	:param results: Patch result rows
	:param changed: Whether output differs from input
	'''

	matched = 0

	for result in results:
		count = result['count']

		if count:
			matched += count
			print(f'{count:4d} {result["name"]}')

	print(f'matches: {matched}')
	print(f'changed: {"yes" if changed else "no"}')


def validate_rules(rules: list[dict[str, object]]):
	'''
	Validate patch rules before binary modification.

	:param rules: Replacement rules
	'''

	for rule in rules:
		find = rule['find']
		replace = rule['replace']

		if not find:
			raise ValueError(f'empty search bytes in rule: {rule["name"]}')

		if len(find) != len(replace):
			raise ValueError(f'rule length mismatch: {rule["name"]}')


def write_binary(path: str, data: bytes):
	'''
	Write a binary file.

	:param path: The binary file path
	:param data: The binary data
	'''

	with open(path, 'wb') as binary_file:
		binary_file.write(data)



if __name__ == '__main__':
	raise SystemExit(main())

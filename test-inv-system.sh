#!/usr/bin/env bash
# Runs the inventory-system test suite from any working directory.

set -u

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
godot_bin="${GODOT_BIN:-Godot}"

if ! command -v "$godot_bin" >/dev/null 2>&1; then
	printf 'FAIL: Godot executable "%s" was not found. Set GODOT_BIN to its path.\n' "$godot_bin"
	exit 127
fi

printf 'Running inventory-system tests with %s\n' "$godot_bin"
"$godot_bin" --headless --path "$script_dir" --script res://tests/inventory_test.gd
test_status=$?

if [ "$test_status" -eq 0 ]; then
	printf 'PASS: inventory-system test suite completed successfully.\n'
else
	printf 'FAIL: inventory-system test suite failed with exit code %d.\n' "$test_status"
fi

exit "$test_status"

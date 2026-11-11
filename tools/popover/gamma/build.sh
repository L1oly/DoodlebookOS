#!/bin/sh
# Build the small wlr-gamma-control helper used for the Quick Settings
# night-light button. Usage: build.sh [output-path]
set -eu
cd "$(dirname "$0")"
out="${1:-doodlebook-gamma}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
wayland-scanner client-header gamma.xml "$tmp/gamma-protocol.h"
wayland-scanner private-code gamma.xml "$tmp/gamma-protocol.c"
${CC:-cc} -O2 -Wall -Wextra -I"$tmp" -o "$out" main.c "$tmp/gamma-protocol.c" \
    $(pkg-config --cflags --libs wayland-client) -lm

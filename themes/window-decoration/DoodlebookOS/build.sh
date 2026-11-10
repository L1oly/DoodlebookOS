#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================================
# DoodlebookOS - Window Decoration Builder & Installer
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="/tmp/doodlebookos-deco-build"

rm -rf "$BUILD_DIR"

echo "[i] Configuring DoodlebookOS Window Decoration..."
cmake -B "$BUILD_DIR" -S "$DIR" -G Ninja -DCMAKE_INSTALL_PREFIX="$HOME/.local" -DCMAKE_BUILD_TYPE=Release

echo "[i] Compiling DoodlebookOS Window Decoration..."
cmake --build "$BUILD_DIR" -j"$(nproc)"

SO_FILE="$(find "$BUILD_DIR" -name "org.doodlebookos.decoration.so" | head -n 1)"
if [[ -z "$SO_FILE" || ! -f "$SO_FILE" ]]; then
    echo "[!] Error: org.doodlebookos.decoration.so was not produced by the build."
    rm -rf "$BUILD_DIR"
    exit 1
fi

echo "[i] Installing DoodlebookOS Window Decoration..."
for libdir in lib64 lib; do
    mkdir -p "$HOME/.local/${libdir}/plugins/org.kde.kdecoration3"
    mkdir -p "$HOME/.local/${libdir}/qt6/plugins/org.kde.kdecoration3"
    cp -f "$SO_FILE" "$HOME/.local/${libdir}/plugins/org.kde.kdecoration3/org.doodlebookos.decoration.so"
    ln -sf "$HOME/.local/${libdir}/plugins/org.kde.kdecoration3/org.doodlebookos.decoration.so" \
           "$HOME/.local/${libdir}/qt6/plugins/org.kde.kdecoration3/org.doodlebookos.decoration.so"
done

if command -v kwriteconfig6 &>/dev/null; then
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.doodlebookos.decoration
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme DoodlebookOS
fi

QDBUS_BIN="$(command -v qdbus-qt6 || command -v qdbus6 || command -v qdbus || true)"
if [[ -n "$QDBUS_BIN" ]] && "$QDBUS_BIN" org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1; then
    echo "[✓] KWin reconfigured successfully."
fi

rm -rf "$BUILD_DIR"
echo "[✓] DoodlebookOS Window Decoration built and activated."

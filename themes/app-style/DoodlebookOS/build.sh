#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================================
# DoodlebookOS - Application Style Builder & Installer
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="/tmp/doodlebookos-style-build"

rm -rf "$BUILD_DIR"

echo "[i] Configuring DoodlebookOS Application Style..."
cmake -B "$BUILD_DIR" -S "$DIR" -G Ninja -DCMAKE_INSTALL_PREFIX="$HOME/.local" -DCMAKE_BUILD_TYPE=Release

echo "[i] Compiling DoodlebookOS Application Style..."
cmake --build "$BUILD_DIR" -j"$(nproc)"

SO_FILE="$(find "$BUILD_DIR" -name "doodlebookos6.so" | head -n 1)"
if [[ -z "$SO_FILE" || ! -f "$SO_FILE" ]]; then
    echo "[!] Error: doodlebookos6.so was not produced by the build."
    rm -rf "$BUILD_DIR"
    exit 1
fi

echo "[i] Installing DoodlebookOS Application Style..."
for libdir in lib64 lib; do
    mkdir -p "$HOME/.local/${libdir}/plugins/styles"
    mkdir -p "$HOME/.local/${libdir}/qt6/plugins/styles"
    cp -f "$SO_FILE" "$HOME/.local/${libdir}/plugins/styles/doodlebookos6.so"
    ln -sf "$HOME/.local/${libdir}/plugins/styles/doodlebookos6.so" \
           "$HOME/.local/${libdir}/qt6/plugins/styles/doodlebookos6.so"
done

mkdir -p "$HOME/.local/share/kstyle/themes"
cp -f "$DIR/doodlebookos.themerc" "$HOME/.local/share/kstyle/themes/doodlebookos.themerc"

if command -v kwriteconfig6 &>/dev/null; then
    kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle DoodlebookOS
fi

rm -rf "$BUILD_DIR"
echo "[✓] DoodlebookOS Application Style built and activated successfully."

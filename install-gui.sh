#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================================
# DoodlebookOS Suite — Graphical OOBE Setup Wizard Launcher
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOODLEBOOK_GUI_ELEVATE=1 DOODLEBOOK_PREP_ONLY=1 bash "$SCRIPT_DIR/install.sh"
exec python3 "$SCRIPT_DIR/installer/installer.py" "$@"

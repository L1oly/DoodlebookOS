#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================================
# DoodlebookOS Suite — Command-Line & Core Prerequisite Installer
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ELEVATE="sudo"
if [[ "${DOODLEBOOK_GUI_ELEVATE:-0}" == "1" ]] && command -v pkexec &>/dev/null && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
    ELEVATE="pkexec"
fi

need_packages=0
if ! command -v python3 &>/dev/null || ! python3 -c "import PySide6, PIL, dbus, gi" &>/dev/null; then
    need_packages=1
fi
if ! command -v cmake &>/dev/null || ! command -v ninja &>/dev/null || ! command -v g++ &>/dev/null; then
    need_packages=1
fi
# Check if KDecoration3 / KStyle CMake configs exist on the system
if [[ ! -d "/usr/lib64/cmake/KDecoration3" && ! -d "/usr/lib/cmake/KDecoration3" && ! -d "/usr/lib/x86_64-linux-gnu/cmake/KDecoration3" ]]; then
    need_packages=1
fi
if [[ ! -d "/usr/lib64/cmake/KF6Style" && ! -d "/usr/lib/cmake/KF6Style" && ! -d "/usr/lib/x86_64-linux-gnu/cmake/KF6Style" && ! -d "/usr/lib64/cmake/KF6FrameworkIntegration" && ! -d "/usr/lib/cmake/KF6FrameworkIntegration" && ! -d "/usr/lib/x86_64-linux-gnu/cmake/KF6FrameworkIntegration" ]]; then
    need_packages=1
fi

# Find system Klipper QML directory across distros
KLIPPER_DIR=""
for cand in \
    "/usr/lib64/qt6/qml/org/kde/plasma/private/clipboard" \
    "/usr/lib/qt6/qml/org/kde/plasma/private/clipboard" \
    "/usr/lib/x86_64-linux-gnu/qt6/qml/org/kde/plasma/private/clipboard" \
    "/usr/lib/aarch64-linux-gnu/qt6/qml/org/kde/plasma/private/clipboard"; do
    if [[ -d "$cand" ]]; then
        KLIPPER_DIR="$cand"
        break
    fi
done

KLIPPER_SRC="$SCRIPT_DIR/system-overrides/plasma/clipboard/KlipperPopup.qml"
KLIPPER_ICONS_SRC="$SCRIPT_DIR/system-overrides/plasma/clipboard/icons"

need_klipper_override=0
if [[ -n "$KLIPPER_DIR" && -f "$KLIPPER_SRC" ]]; then
    if ! cmp -s "$KLIPPER_SRC" "$KLIPPER_DIR/KlipperPopup.qml" 2>/dev/null; then
        need_klipper_override=1
    elif [[ -f "$KLIPPER_DIR/qmldir" ]] && grep -q "^prefer :" "$KLIPPER_DIR/qmldir" 2>/dev/null; then
        need_klipper_override=1
    elif [[ ! -d "$KLIPPER_DIR/icons" ]]; then
        need_klipper_override=1
    fi
fi

if [[ "$need_packages" -eq 1 || "$need_klipper_override" -eq 1 ]]; then
    echo "[i] Preparing system dependencies and KDE Plasma overrides (administrator privileges required)..."
    ROOT_SCRIPT="/tmp/doodlebookos-root-prep-$$.sh"
    cat > "$ROOT_SCRIPT" <<EOF
#!/usr/bin/env bash
if [[ "$need_packages" -eq 1 ]]; then
    if command -v dnf &>/dev/null; then
        dnf install -y --skip-unavailable python3 python3-pyside6 python3-pillow python3-dbus python3-gobject \
            cmake ninja-build gcc-c++ extra-cmake-modules \
            qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtdeclarative-devel qt6-qtsvg-devel \
            kf6-kcoreaddons-devel kf6-kconfig-devel kf6-kwindowsystem-devel kf6-kguiaddons-devel \
            kf6-ki18n-devel kf6-kiconthemes-devel kf6-kconfigwidgets-devel kf6-kcmutils-devel \
            kf6-frameworkintegration-devel kf6-kcolorscheme-devel kf6-kirigami-devel \
            kdecoration-devel || true
    elif command -v pacman &>/dev/null; then
        pacman -S --needed --noconfirm python pyside6 python-pillow python-dbus python-gobject \
            cmake ninja gcc extra-cmake-modules \
            qt6-base qt6-declarative qt6-svg \
            kcoreaddons kconfig kwindowsystem kguiaddons ki18n kiconthemes \
            kconfigwidgets kcmutils frameworkintegration kcolorscheme kirigami kdecoration || true
    elif command -v apt-get &>/dev/null; then
        apt-get update && apt-get install -y \
            python3 python3-pil python3-dbus python3-gi \
            python3-pyside6.qtcore python3-pyside6.qtgui python3-pyside6.qtqml \
            python3-pyside6.qtquick python3-pyside6.qtdbus \
            cmake ninja-build g++ extra-cmake-modules pkg-config \
            qt6-base-dev qt6-base-private-dev qt6-declarative-dev libqt6svg6-dev \
            libkf6coreaddons-dev libkf6config-dev libkf6windowsystem-dev libkf6guiaddons-dev \
            libkf6i18n-dev libkf6iconthemes-dev libkf6configwidgets-dev libkf6kcmutils-dev \
            libkf6style-dev libkf6colorscheme-dev kirigami-addons-dev || true
        apt-get install -y libkdecoration3-dev 2>/dev/null || apt-get install -y libkdecoration-dev 2>/dev/null || true
    elif command -v zypper &>/dev/null; then
        zypper install -y python3 python3-pyside6 python3-Pillow python3-dbus-python python3-gobject \
            cmake ninja gcc-c++ extra-cmake-modules \
            qt6-base-devel qt6-base-private-devel qt6-declarative-devel qt6-svg-devel \
            kf6-kcoreaddons-devel kf6-kconfig-devel kf6-kwindowsystem-devel kf6-kguiaddons-devel \
            kf6-ki18n-devel kf6-kiconthemes-devel kf6-kconfigwidgets-devel kf6-kcmutils-devel \
            kf6-frameworkintegration-devel kf6-kcolorscheme-devel kf6-kirigami-devel kdecoration6-devel || true
    fi
fi

if [[ "$need_klipper_override" -eq 1 && -n "$KLIPPER_DIR" && -d "$KLIPPER_DIR" ]]; then
    if [[ -f "$KLIPPER_DIR/KlipperPopup.qml" && ! -f "$KLIPPER_DIR/KlipperPopup.qml.orig" ]]; then
        cp -f "$KLIPPER_DIR/KlipperPopup.qml" "$KLIPPER_DIR/KlipperPopup.qml.orig"
    fi
    if [[ -f "$KLIPPER_DIR/qmldir" && ! -f "$KLIPPER_DIR/qmldir.orig" ]]; then
        cp -f "$KLIPPER_DIR/qmldir" "$KLIPPER_DIR/qmldir.orig"
    fi
    cp -f "$KLIPPER_SRC" "$KLIPPER_DIR/KlipperPopup.qml"
    if [[ -d "$KLIPPER_ICONS_SRC" ]]; then
        rm -rf "$KLIPPER_DIR/icons"
        cp -r "$KLIPPER_ICONS_SRC" "$KLIPPER_DIR/icons"
    fi
    if [[ -f "$KLIPPER_DIR/qmldir" ]]; then
        sed -i '/^prefer :/d' "$KLIPPER_DIR/qmldir"
    fi
fi
EOF
    chmod +x "$ROOT_SCRIPT"
    $ELEVATE bash "$ROOT_SCRIPT" || echo "[!] Warning: System preparation script returned non-zero status; continuing..."
    rm -f "$ROOT_SCRIPT"

    if ! command -v cmake &>/dev/null || ! command -v ninja &>/dev/null || ! command -v g++ &>/dev/null; then
        echo "[!] Error: Critical build tools (cmake, ninja, g++) are still missing after prerequisite installation."
        echo "[!] Please ensure package repositories are enabled and run the installer again."
        exit 1
    fi
fi

if [[ "${DOODLEBOOK_PREP_ONLY:-0}" == "1" ]]; then
    exit 0
fi

exec python3 "$SCRIPT_DIR/installer/installer.py" --cli "$@"

#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================================
# DoodlebookOS — Uninstaller & Backup Restorer for KDE Plasma 6
# ==============================================================================
set -e

C_RESET="\033[0m"
C_BOLD="\033[1m"
C_GREEN="\033[32m"
C_CYAN="\033[36m"

echo -e "${C_CYAN}${C_BOLD}==> Uninstalling DoodlebookOS...${C_RESET}"

# 1. Stop Daemons & Revert Environment
if command -v systemctl &>/dev/null; then
    systemctl --user stop doodlebookos-topbar.service 2>/dev/null || true
    systemctl --user disable doodlebookos-topbar.service 2>/dev/null || true
fi
rm -f "$HOME/.config/systemd/user/doodlebookos-topbar.service"
rm -f "$HOME/.config/systemd/user/plasma-krunner.service"
rm -f "$HOME/.local/bin/doodlebookos-topbar-color" \
      "$HOME/.local/bin/dostheme" \
      "$HOME/.local/bin/doodlebook-krunner-bridge.py" \
      "$HOME/.local/bin/doodlebook-icon-studio"
rm -f "$HOME/.local/share/applications/doodlebook-icon-studio.desktop"
rm -rf "$HOME/.local/share/doodlebookos/icon-studio"
rm -f "$HOME/.config/environment.d/10-qt-plugins.conf"

if command -v systemctl &>/dev/null; then
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user restart plasma-krunner.service 2>/dev/null || true
fi

# 2. Revert Theme, Style, Decoration, Icons & Cursors to KDE Breeze Defaults
if command -v plasma-apply-desktoptheme &>/dev/null; then
    plasma-apply-desktoptheme breeze-dark &>/dev/null || plasma-apply-desktoptheme default &>/dev/null || true
fi
if command -v kwriteconfig6 &>/dev/null; then
    kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "breeze_cursors"
    kwriteconfig6 --file kdeglobals --group Icons --key Theme "breeze"
    kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "Breeze"
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.breeze"
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme "Breeze"
fi

# 3. Remove Installed Themes, Icons, Cursors, Wallpapers, Fonts & C++ Plugins
rm -rf "$HOME/.local/share/plasma/desktoptheme/DoodlebookOS_Dark" \
       "$HOME/.local/share/plasma/desktoptheme/DoodlebookOS_Light" \
       "$HOME/.local/share/plasma/desktoptheme/GOS_Plasma" \
       "$HOME/.local/share/plasma/desktoptheme/GOS_Plasma_Light"
rm -f "$HOME/.local/share/color-schemes/DoodlebookOS_DARK.colors" \
      "$HOME/.local/share/color-schemes/DoodlebookOS_LIGHT.colors"
rm -rf "$HOME/.local/share/plasma/look-and-feel/org.doodlebookos.desktop"
rm -rf "$HOME/.local/share/icons/DoodlebookOS" \
       "$HOME/.local/share/icons/DoodlebookOS-Cursors" \
       "$HOME/.icons/DoodlebookOS-Cursors"
rm -rf "$HOME/.local/share/fonts/GoogleSansFlex"
rm -rf "$HOME/.local/share/wallpapers/DoodlebookOS"
rm -f "$HOME/.local/share/kstyle/themes/doodlebookos.themerc"

# 4. Remove DoodlebookOS Plasmoids & Linked Applet Plugins
for w in \
    org.doodlebookos.dock DoodlebookOS-Dock \
    org.doodlebookos.statuscluster DoodlebookOS-StatusCluster \
    org.doodlebookos.datetime DoodlebookOS-DateTime \
    org.doodlebookos.clock local.pixelclock DoodlebookOS-Clock \
    org.doodlebookos.weather local.pixelweather DoodlebookOS-Weather \
    org.doodlebookos.upnext org.doodlebookos.glance DoodlebookOS-Glance \
    org.doodlebookos.appgroup org.doodlebookos.folder DoodlebookOS-Folder \
    org.kde.desktopcontainment DoodlebookOS-Desktop org.kde.plasma.folder \
    org.doodlebookos.panelspacer DoodlebookOS-PanelSpacer; do
    rm -rf "$HOME/.local/share/plasma/plasmoids/$w"
done

for libdir in lib64 lib; do
    rm -f "$HOME/.local/${libdir}/qt6/plugins/plasma/applets/org.doodlebookos.statuscluster.so"
    rm -f "$HOME/.local/${libdir}/plugins/plasma/applets/org.doodlebookos.statuscluster.so"
    rm -f "$HOME/.local/${libdir}/qt6/plugins/plasma/applets/org.doodlebookos.datetime.so"
    rm -f "$HOME/.local/${libdir}/plugins/plasma/applets/org.doodlebookos.datetime.so"
    rm -f "$HOME/.local/${libdir}/qt6/plugins/styles/doodlebookos6.so"
    rm -f "$HOME/.local/${libdir}/plugins/styles/doodlebookos6.so"
    rm -f "$HOME/.local/${libdir}/qt6/plugins/org.kde.kdecoration3/org.doodlebookos.decoration.so"
    rm -f "$HOME/.local/${libdir}/plugins/org.kde.kdecoration3/org.doodlebookos.decoration.so"
done

# 5. Restore User Configuration from Latest Backup (if available)
LATEST_BACKUP="$HOME/.config/doodlebookos-backups/latest"
if [[ -d "$LATEST_BACKUP" ]]; then
    echo -e "${C_CYAN}[i] Restoring user configuration from backup: ${LATEST_BACKUP}...${C_RESET}"
    for cfg_file in plasmarc kdeglobals kwinrc plasmashellrc kglobalshortcutsrc \
                    kcminputrc klaunchrc plasma-org.kde.plasma.desktop-appletsrc; do
        if [[ -f "$LATEST_BACKUP/$cfg_file" ]]; then
            cp -f "$LATEST_BACKUP/$cfg_file" "$HOME/.config/$cfg_file"
        fi
    done
fi

for c_id in $(grep -oE "\[Containments\]\[[0-9]+\]" "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" 2>/dev/null | grep -oE "[0-9]+" | sort -u); do
    kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group ActionPlugins --group "$c_id" --key "RightButton;NoModifier" "org.kde.contextmenu"
done

QDBUS_BIN="$(command -v qdbus-qt6 || command -v qdbus6 || command -v qdbus || true)"
if [[ -n "$QDBUS_BIN" ]]; then
    "$QDBUS_BIN" org.kde.KWin /KWin reconfigure &>/dev/null || true
fi

# 6. Revert System Clipboard Override (across lib64 / lib)
ELEVATE="sudo"
if command -v pkexec &>/dev/null && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]] && [[ ! -t 0 ]]; then
    ELEVATE="pkexec"
fi

for klipper_dir in \
    "/usr/lib64/qt6/qml/org/kde/plasma/private/clipboard" \
    "/usr/lib/qt6/qml/org/kde/plasma/private/clipboard" \
    "/usr/lib/x86_64-linux-gnu/qt6/qml/org/kde/plasma/private/clipboard" \
    "/usr/lib/aarch64-linux-gnu/qt6/qml/org/kde/plasma/private/clipboard"; do
    if [[ -f "$klipper_dir/KlipperPopup.qml.orig" || -f "$klipper_dir/qmldir.orig" ]]; then
        echo "[i] Restoring original Klipper clipboard files in $klipper_dir..."
        $ELEVATE sh -c "
            if [ -f '$klipper_dir/KlipperPopup.qml.orig' ]; then
                mv -f '$klipper_dir/KlipperPopup.qml.orig' '$klipper_dir/KlipperPopup.qml'
            fi
            if [ -f '$klipper_dir/qmldir.orig' ]; then
                mv -f '$klipper_dir/qmldir.orig' '$klipper_dir/qmldir'
            fi
            rm -rf '$klipper_dir/icons'
        " 2>/dev/null || true
    fi
done

# 7. Clear Caches & Restart Plasma
if command -v kbuildsycoca6 &>/dev/null; then
    kbuildsycoca6 --noincremental &>/dev/null || true
fi
rm -f ~/.cache/plasma* ~/.cache/plasma_theme* 2>/dev/null || true

if command -v systemctl &>/dev/null && systemctl --user is-active --quiet plasma-plasmashell.service 2>/dev/null; then
    systemctl --user restart plasma-plasmashell.service 2>/dev/null || true
fi

echo -e "${C_GREEN}${C_BOLD}[✓] DoodlebookOS has been uninstalled and user configuration restored.${C_RESET}"

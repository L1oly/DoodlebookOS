/*
    SPDX-FileCopyrightText: 2026 DoodlebookOS
    SPDX-License-Identifier: GPL-3.0-or-later

    Standalone Quick Settings drawer.

    This is the exact same `quicksettings/FullRepresentation.qml` used by the
    StatusCluster plasmoid, hosted in a layer-shell window by
    tools/popover/doodlebook-popover. Quick Settings and the Notification
    Center are separate drawers; only one is shown at a time.
*/

import QtQuick
import QtQuick.Window
import org.kde.layershell as LayerShell
import org.kde.kirigami as Kirigami
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.plasma.private.battery as PlasmaBattery
import org.kde.plasma.private.volume as Volume
import org.kde.notificationmanager as NotificationManager
import QtCore
import "../quicksettings" as QuickSettingsUI

Window {
    id: window
    objectName: "doodlebookQuickSettingsPopover"
    title: "DoodlebookOS Quick Settings"

    readonly property bool wantsVisible: typeof PopoverState !== "undefined" && PopoverState
        ? PopoverState.quicksettingsVisible : false

    visible: wantsVisible
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    width: qsView.implicitWidth > 0 ? qsView.implicitWidth : 340
    height: qsView.implicitHeight > 0 ? qsView.implicitHeight : 440

    onVisibleChanged: {
        if (!qsView) {
            return;
        }
        if (visible) {
            if (typeof qsView.refreshVolumeStreams === "function") {
                qsView.refreshVolumeStreams();
            }
            if (typeof qsView.refreshAudioDevices === "function") {
                qsView.refreshAudioDevices();
            }
        } else {
            // Start every fresh open with the advanced audio area collapsed.
            qsView.volumeAppsExpanded = false;
            qsView.audioPickerMode = "";
        }
    }

    // Resolve a Material 3 color token from the daemon's matugen palette.
    function md3(name: string, fallback: string): color {
        if (typeof Md3Palette !== "undefined" && Md3Palette && Md3Palette.colors) {
            var value = Md3Palette.colors[name];
            if (value) {
                return value;
            }
        }
        return fallback;
    }

    // Dedicated namespace so compositors can apply a blur/rounded-corner
    // layer rule to the drawer (e.g. niri's layer-rule).
    LayerShell.Window.scope: "doodlebook-quicksettings"
    LayerShell.Window.anchors: LayerShell.Window.AnchorTop | LayerShell.Window.AnchorRight
    LayerShell.Window.margins: ({ left: 8, top: 8, right: 8, bottom: 0 })
    LayerShell.Window.layer: LayerShell.Window.LayerOverlay
    LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityOnDemand
    LayerShell.Window.activateOnShow: true
    LayerShell.Window.wantsToBeOnActiveScreen: true

    Settings {
        id: qsSettings
        category: "doodlebookos-quicksettings"
        property string activeTiles: "wifi,bluetooth,dark_mode,battery_saver,modes,mic,screenshot,quickshare,localshare,powerprofiles,caffeine,tailscale"
        property int tileCatalogVersion: 3
        // 100 = normal range, 150 = allow volume amplification up to 150%.
        property int volumeMax: 100
        // List utility/pipewire streams (soundboard feeders etc.) in App volume.
        property bool showVirtualStreams: false
        property bool useCustomAccentColor: false
        property string accentColor: ""
    }

    // ------------------------------------------------------------------
    // Backend subset needed by the drawer (mirrors StatusCluster main.qml)
    // ------------------------------------------------------------------
    Item {
        id: backend
        anchors.fill: parent
        visible: false

        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        Kirigami.Theme.backgroundColor: window.md3("surface_container", "#1d2024")
        Kirigami.Theme.alternateBackgroundColor: window.md3("surface_container_high", "#272a2f")
        Kirigami.Theme.textColor: window.md3("on_surface", "#e1e2e9")
        Kirigami.Theme.disabledTextColor: window.md3("on_surface_variant", "#c3c6cf")
        Kirigami.Theme.highlightColor: window.md3("primary", "#a4c9fe")
        Kirigami.Theme.highlightedTextColor: window.md3("on_primary", "#00315c")
        Kirigami.Theme.activeTextColor: window.md3("primary", "#a4c9fe")
        Kirigami.Theme.linkColor: window.md3("primary", "#a4c9fe")
        Kirigami.Theme.visitedLinkColor: window.md3("tertiary", "#d9bde3")
        Kirigami.Theme.positiveTextColor: window.md3("tertiary", "#d9bde3")
        Kirigami.Theme.neutralTextColor: window.md3("tertiary", "#d9bde3")
        Kirigami.Theme.negativeTextColor: window.md3("error", "#ffb4ab")

        property alias nmStatus: nmStatus
        property alias batteryModel: batteryModel
        property alias paSinkModel: paSinkModel
        property bool expanded: true
        property var popupAnchorItem: null

        readonly property color effectiveAccentColor: {
            if (qsSettings.useCustomAccentColor && qsSettings.accentColor) {
                return qsSettings.accentColor;
            }
            return Kirigami.Theme.highlightColor;
        }

        readonly property bool hasInternalBattery: Boolean(
            batteryModel &&
            (batteryModel.hasCumulative || (batteryModel.hasInternalBatteries && batteryModel.percent > 0))
        )

        readonly property bool isDndActive: Boolean(
            notifSettings.notificationsInhibitedUntil &&
            notifSettings.notificationsInhibitedUntil > new Date()
        )

        function toggleDoNotDisturbMode(): void {
            if (isDndActive) {
                notifSettings.notificationsInhibitedUntil = undefined;
            } else {
                var d = new Date();
                d.setFullYear(d.getFullYear() + 1);
                notifSettings.notificationsInhibitedUntil = d;
            }
            notifSettings.save();
        }

        NotificationManager.Settings {
            id: notifSettings
        }

        PlasmaNM.NetworkStatus {
            id: nmStatus
        }

        PlasmaNM.EnabledConnections {
            id: nmEnabled
        }

        PlasmaNM.NetworkModel {
            id: nmNetworkModel
        }

        PlasmaNM.AppletProxyModel {
            id: nmAppletProxyModel
            sourceModel: nmNetworkModel
        }

        PlasmaBattery.BatteryControlModel {
            id: batteryModel
        }

        Volume.SinkModel {
            id: paSinkModel
        }

        property int activeWifiSignal: -1
        property bool hasActiveWifi: false
        property bool hasActiveWired: false

        function updateWifiSignal() {
            var foundWired = false;
            var foundWifi = false;
            var wifiSig = -1;

            var count = nmAppletProxyModel.rowCount();
            for (var i = 0; i < count; i++) {
                var idx = nmAppletProxyModel.index(i, 0);
                var state = nmAppletProxyModel.data(idx, PlasmaNM.NetworkModel.ConnectionStateRole);
                var type = nmAppletProxyModel.data(idx, PlasmaNM.NetworkModel.TypeRole);

                if (state === PlasmaNM.Enums.Activated) {
                    if (type === PlasmaNM.Enums.Wired) {
                        foundWired = true;
                    } else if (type === PlasmaNM.Enums.Wireless && !foundWifi) {
                        var sig = nmAppletProxyModel.data(idx, PlasmaNM.NetworkModel.SignalRole);
                        wifiSig = (sig !== undefined && sig !== null && !isNaN(sig)) ? Number(sig) : 100;
                        foundWifi = true;
                    }
                }
            }

            hasActiveWired = foundWired;
            hasActiveWifi = foundWifi;
            activeWifiSignal = wifiSig;
        }

        Connections {
            target: nmAppletProxyModel
            function onDataChanged() { backend.updateWifiSignal(); }
            function onRowsInserted() { backend.updateWifiSignal(); }
            function onRowsRemoved() { backend.updateWifiSignal(); }
            function onModelReset() { backend.updateWifiSignal(); }
        }

        Connections {
            target: nmEnabled
            function onWirelessEnabledChanged() { backend.updateWifiSignal(); }
        }

        Component.onCompleted: updateWifiSignal()

        readonly property url currentWifiIcon: {
            if (hasActiveWired) {
                return Qt.resolvedUrl("../quicksettings/icons/ethernet.svg");
            }
            if (!nmEnabled.wirelessEnabled) {
                return Qt.resolvedUrl("../quicksettings/icons/wifi_off.svg");
            }
            if (!hasActiveWifi) {
                return Qt.resolvedUrl("../quicksettings/icons/wifi_0.svg");
            }
            if (activeWifiSignal <= 33) {
                return Qt.resolvedUrl("../quicksettings/icons/wifi_1.svg");
            } else if (activeWifiSignal <= 66) {
                return Qt.resolvedUrl("../quicksettings/icons/wifi_2.svg");
            }
            return Qt.resolvedUrl("../quicksettings/icons/wifi_3.svg");
        }

        readonly property url currentBatteryIcon: {
            var bm = batteryModel;
            if (!bm) {
                return Qt.resolvedUrl("../quicksettings/icons/battery_android_full_bolt.svg");
            }

            var val = (bm.percent !== undefined && bm.percent !== null) ? bm.percent : 100;
            var isPlugged = Boolean(bm.pluggedIn || bm.state === 1 || bm.state === 3);

            if (!hasInternalBattery) {
                return Qt.resolvedUrl("../quicksettings/icons/battery_android_full_bolt.svg");
            }

            if (isPlugged) {
                if (val <= 15) return Qt.resolvedUrl("../quicksettings/icons/battery_android_bolt.svg");
                if (val <= 35) return Qt.resolvedUrl("../quicksettings/icons/battery_android_2_bolt.svg");
                if (val <= 55) return Qt.resolvedUrl("../quicksettings/icons/battery_android_4_bolt.svg");
                if (val <= 75) return Qt.resolvedUrl("../quicksettings/icons/battery_android_5_bolt.svg");
                if (val <= 92) return Qt.resolvedUrl("../quicksettings/icons/battery_android_6_bolt.svg");
                return Qt.resolvedUrl("../quicksettings/icons/battery_android_full_bolt.svg");
            }

            if (val <= 5) return Qt.resolvedUrl("../quicksettings/icons/battery_android_alert.svg");
            if (val <= 15) return Qt.resolvedUrl("../quicksettings/icons/battery_android_0.svg");
            if (val <= 35) return Qt.resolvedUrl("../quicksettings/icons/battery_android_2.svg");
            if (val <= 55) return Qt.resolvedUrl("../quicksettings/icons/battery_android_4.svg");
            if (val <= 75) return Qt.resolvedUrl("../quicksettings/icons/battery_android_5.svg");
            if (val <= 92) return Qt.resolvedUrl("../quicksettings/icons/battery_android_6.svg");
            return Qt.resolvedUrl("../quicksettings/icons/battery_android_full.svg");
        }

        Connections {
            target: backend
            function onExpandedChanged() {
                if (!backend.expanded && typeof PopoverState !== "undefined" && PopoverState) {
                    PopoverState.hideQuicksettings();
                }
            }
        }
    }

    // Material 3 popover surface. The plasmoid gets this from plasmashell's
    // dialog background; a standalone layer-shell window has to draw it.
    Rectangle {
        id: panelBackground
        anchors.fill: parent
        radius: 24
        // Slightly translucent so a compositor blur layer rule shows through.
        color: {
            var c = window.md3("surface_container_lowest", "#0c0e13");
            return Qt.rgba(c.r, c.g, c.b, 0.80);
        }
        border.width: 1
        border.color: window.md3("outline_variant", "#43474e")
    }

    QuickSettingsUI.FullRepresentation {
        id: qsView
        appletRoot: backend
        settings: qsSettings

        background: null

        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        Kirigami.Theme.backgroundColor: window.md3("surface_container", "#1d2024")
        Kirigami.Theme.alternateBackgroundColor: window.md3("surface_container_high", "#272a2f")
        Kirigami.Theme.textColor: window.md3("on_surface", "#e1e2e9")
        Kirigami.Theme.disabledTextColor: window.md3("on_surface_variant", "#c3c6cf")
        Kirigami.Theme.highlightColor: window.md3("primary", "#a4c9fe")
        Kirigami.Theme.highlightedTextColor: window.md3("on_primary", "#00315c")
        Kirigami.Theme.activeTextColor: window.md3("primary", "#a4c9fe")
        Kirigami.Theme.linkColor: window.md3("primary", "#a4c9fe")
        Kirigami.Theme.visitedLinkColor: window.md3("tertiary", "#d9bde3")
        Kirigami.Theme.positiveTextColor: window.md3("tertiary", "#d9bde3")
        Kirigami.Theme.neutralTextColor: window.md3("tertiary", "#d9bde3")
        Kirigami.Theme.negativeTextColor: window.md3("error", "#ffb4ab")
    }
}

/*
    SPDX-FileCopyrightText: 2026 DoodlebookOS
    SPDX-License-Identifier: GPL-3.0-or-later

    Standalone Notification Center.

    Reuses `notifications/FullRepresentation.qml` from the StatusCluster
    plasmoid inside its own layer-shell window, so it can be opened from Waybar
    (or any other launcher). Quick Settings and the Notification Center are
    separate drawers; only one is shown at a time.
*/

import QtQuick
import QtQuick.Window
import org.kde.layershell as LayerShell
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.notificationmanager as NotificationManager
import "../notifications" as NotificationsUI

Window {
    id: window
    objectName: "doodlebookNotificationCenterPopover"
    title: "DoodlebookOS Notification Center"

    readonly property bool wantsVisible: typeof PopoverState !== "undefined" && PopoverState
        ? PopoverState.notificationsVisible : false

    visible: wantsVisible
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    width: ncView.implicitWidth > 0 ? ncView.implicitWidth : 340
    height: ncView.implicitHeight > 0 ? ncView.implicitHeight : 240

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
    LayerShell.Window.scope: "doodlebook-notifications"
    LayerShell.Window.anchors: LayerShell.Window.AnchorTop | LayerShell.Window.AnchorRight
    LayerShell.Window.margins: ({ left: 8, top: 8, right: 8, bottom: 0 })
    LayerShell.Window.layer: LayerShell.Window.LayerOverlay
    LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityOnDemand
    LayerShell.Window.activateOnShow: true
    LayerShell.Window.wantsToBeOnActiveScreen: true

    NotificationManager.Settings {
        id: notifSettings
    }

    NotificationManager.Notifications {
        id: historyModel
        showExpired: true
        showDismissed: true
        showJobs: notifSettings.jobsInNotifications
        sortMode: NotificationManager.Notifications.SortByTypeAndUrgency
        groupMode: NotificationManager.Notifications.GroupDisabled
        ignoreBlacklistDuringInhibition: true
        blacklistedDesktopEntries: notifSettings.historyBlacklistedApplications
        blacklistedNotifyRcNames: notifSettings.historyBlacklistedServices
        urgencies: NotificationManager.Notifications.CriticalUrgency
                 | NotificationManager.Notifications.NormalUrgency
                 | NotificationManager.Notifications.LowUrgency
    }

    PlasmaCore.Action {
        id: clearHistoryAction
        text: "Clear All Notifications"
        icon.name: "edit-clear-history"
        visible: historyModel.expiredNotificationsCount > 0
        onTriggered: {
            historyModel.clear(NotificationManager.Notifications.ClearExpired);
        }
    }

    function syncState(): void {
        if (typeof PopoverState === "undefined" || !PopoverState) {
            return;
        }
        PopoverState.unreadCount = Math.min(99, Math.max(0, historyModel.unreadNotificationsCount));
        PopoverState.dndActive = Boolean(
            notifSettings.notificationsInhibitedUntil &&
            notifSettings.notificationsInhibitedUntil > new Date()
        );
    }

    Component.onCompleted: syncState()

    Connections {
        target: historyModel
        function onRowsInserted() { window.syncState(); }
        function onRowsRemoved() { window.syncState(); }
        function onDataChanged() { window.syncState(); }
        function onModelReset() { window.syncState(); }
        function onUnreadNotificationsCountChanged() { window.syncState(); }
    }

    Connections {
        target: notifSettings
        function onNotificationsInhibitedUntilChanged() { window.syncState(); }
    }

    onVisibleChanged: {
        if (visible) {
            historyModel.lastRead = undefined;
            Qt.callLater(syncState);
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

    NotificationsUI.FullRepresentation {
        id: ncView
        appletInterface: null
        clearHistoryAction: clearHistoryAction
        historyModel: historyModel

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

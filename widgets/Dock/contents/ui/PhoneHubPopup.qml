/*
 * SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kdeconnect as KDEConnect
import "i18n.js" as I18n

PlasmaCore.Dialog {
    id: root

    function i18n(k, a1, a2) { return I18n.t(k, a1, a2); }

    property Item visualParentItem: null

    objectName: "phoneHubPopup"
    flags: Qt.WindowStaysOnTopHint

    visualParent: null
    location: (typeof Plasmoid !== "undefined" && Plasmoid.location !== undefined) ? Plasmoid.location : PlasmaCore.Types.BottomEdge
    floating: 16
    hideOnWindowDeactivate: true
    backgroundHints: PlasmaCore.Types.StandardBackground

    property int popupWidth: 440
    property int popupHeight: 520
    property real panelHeight: 52

    width: popupWidth
    height: popupHeight

    property bool isDndActive: false
    property bool isRinging: false

    property bool hasDevice: false
    property string deviceId: ""
    property string deviceName: i18n("Phone")

    function updatePosition() {
        var scr = (visualParentItem && visualParentItem.Screen) ? visualParentItem.Screen : Screen;
        var scrWidth = scr.width;
        var scrHeight = scr.height;
        var scrX = (scr.virtualX !== undefined) ? scr.virtualX : 0;
        var scrY = (scr.virtualY !== undefined) ? scr.virtualY : 0;

        var effPanelHeight = root.panelHeight;
        if (visualParentItem && visualParentItem.Window && visualParentItem.Window.window && visualParentItem.Window.window.height > 0) {
            effPanelHeight = visualParentItem.Window.window.height;
        }

        var bottomGap = 16;
        var currentW = root.width > 0 ? root.width : popupWidth;
        var currentH = root.height > 0 ? root.height : popupHeight;
        var panelTop = scrY + scrHeight - effPanelHeight;
        var targetY = Math.max(24, Math.round(panelTop - currentH - bottomGap));

        var targetX = scrX + Math.round((scrWidth - currentW) / 2);
        if (visualParentItem) {
            var btnCenterX = 0;
            if (typeof visualParentItem.mapToGlobal === "function") {
                try {
                    var gPt = visualParentItem.mapToGlobal(visualParentItem.width / 2, 0);
                    if (gPt && gPt.x !== undefined && gPt.x > 0) btnCenterX = gPt.x;
                } catch (e) {}
            }
            if (btnCenterX === 0 && typeof visualParentItem.mapToItem === "function") {
                try {
                    var lPt = visualParentItem.mapToItem(null, visualParentItem.width / 2, 0);
                    var winX = (visualParentItem.Window && visualParentItem.Window.window) ? visualParentItem.Window.window.x : 0;
                    btnCenterX = winX + lPt.x;
                } catch (e2) {}
            }
            if (btnCenterX > 0) targetX = Math.round(btnCenterX - currentW / 2);
        }

        targetX = Math.max(scrX + 16, Math.min(scrX + scrWidth - currentW - 16, targetX));
        if (root.x !== targetX) root.x = targetX;
        if (root.y !== targetY) root.y = targetY;
    }

    function toggle() {
        if (root.visible) close(); else open();
    }

    function open() {
        updatePosition();
        root.visible = true;
        updatePosition();
        root.requestActivate();
    }

    function close() {
        root.visible = false;
    }

    onVisibleChanged: {
        if (visible) updatePosition();
    }
    onWidthChanged: { if (visible) updatePosition(); }
    onHeightChanged: { if (visible) updatePosition(); }

    mainItem: Item {
        id: container
        implicitWidth: root.popupWidth
        implicitHeight: root.popupHeight
        width: root.popupWidth
        height: root.popupHeight

        Plasma5Support.DataSource {
            id: executor
            engine: "executable"
            connectedSources: []
            onNewData: (sourceName, data) => disconnectSource(sourceName)
            function exec(cmd) {
                var fullCmd = "nohup sh -c " + JSON.stringify(cmd) + " </dev/null >/dev/null 2>&1 & # " + Date.now();
                connectSource(fullCmd);
            }
        }

        KDEConnect.DevicesModel {
            id: devicesModel
            displayFilter: KDEConnect.DevicesModel.Paired | KDEConnect.DevicesModel.Reachable

            onCountChanged: updateDeviceData()
            onDataChanged: updateDeviceData()
            onRowsInserted: updateDeviceData()
            onRowsRemoved: updateDeviceData()
            Component.onCompleted: updateDeviceData()

            function updateDeviceData() {
                root.hasDevice = devicesModel.count > 0;
                if (root.hasDevice) {
                    var idx = devicesModel.index(0, 0);
                    var devId = devicesModel.data(idx, 256);
                    if (!devId) devId = devicesModel.data(idx, Qt.UserRole);
                    root.deviceId = devId ? devId.toString() : "";
                    var name = devicesModel.data(idx, Qt.DisplayRole);
                    root.deviceName = name ? name.toString() : root.i18n("Phone");
                } else {
                    root.deviceId = "";
                    root.deviceName = root.i18n("No connected phone");
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // 1. Centered phone name in Google Sans Flex
            Text {
                Layout.fillWidth: true
                Layout.topMargin: 6
                Layout.bottomMargin: 8
                horizontalAlignment: Text.AlignHCenter
                text: root.deviceName
                font.family: "Google Sans Flex"
                font.pixelSize: 18
                font.weight: Font.DemiBold
                color: "#FFFFFF"
                elide: Text.ElideRight
            }

            // 2. 2x2 Expressive Quick Action Tiles grid
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10
                enabled: root.hasDevice

                // Tile 1: Ring (Find My Phone)
                PhoneHubActionTile {
                    Layout.fillWidth: true
                    title: root.isRinging ? root.i18n("Ringing…") : root.i18n("Ring")
                    iconSource: Qt.resolvedUrl("icons/mobile_ring.svg")
                    isActive: root.isRinging
                    activeColor: "#EA4335"
                    onClicked: {
                        if (!root.deviceId) return;
                        root.isRinging = !root.isRinging;
                        executor.exec("$(command -v qdbus-qt6 || command -v qdbus6 || command -v qdbus) org.kde.kdeconnect /modules/kdeconnect/devices/" + root.deviceId + "/findmyphone org.kde.kdeconnect.device.findmyphone.ring");
                    }
                }

                // Tile 2: Files (SFTP / Dolphin)
                PhoneHubActionTile {
                    Layout.fillWidth: true
                    title: root.i18n("Files")
                    iconSource: Qt.resolvedUrl("icons/files.svg")
                    onClicked: {
                        if (!root.deviceId) return;
                        executor.exec("$(command -v qdbus-qt6 || command -v qdbus6 || command -v qdbus) org.kde.kdeconnect /modules/kdeconnect/devices/" + root.deviceId + "/sftp org.kde.kdeconnect.device.sftp.startBrowsing");
                        root.close();
                    }
                }

                // Tile 3: Send (Share clipboard / file)
                PhoneHubActionTile {
                    Layout.fillWidth: true
                    title: root.i18n("Send")
                    iconSource: Qt.resolvedUrl("icons/send_to.svg")
                    onClicked: {
                        if (!root.deviceId) return;
                        executor.exec("kdeconnect-handler --device " + root.deviceId + " --share || kdeconnect-app &");
                    }
                }

                // Tile 4: Do Not Disturb (DND)
                PhoneHubActionTile {
                    Layout.fillWidth: true
                    title: root.i18n("Do not disturb")
                    iconSource: Qt.resolvedUrl("icons/dnd.svg")
                    isActive: root.isDndActive
                    activeColor: "#8AB4F8"
                    onClicked: {
                        root.isDndActive = !root.isDndActive;
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // 3. Notifications section header
            RowLayout {
                Layout.fillWidth: true
                visible: root.hasDevice

                Text {
                    Layout.fillWidth: true
                    text: root.i18n("Notifications")
                    font.family: "Google Sans Flex"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Qt.rgba(1, 1, 1, 0.70)
                }

                Text {
                    text: root.i18n("Clear all")
                    font.family: "Google Sans Flex"
                    font.pixelSize: 12
                    color: clearMa.containsMouse ? Kirigami.Theme.highlightColor : Qt.rgba(1, 1, 1, 0.50)
                    visible: notifsModel.count > 0

                    MouseArea {
                        id: clearMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof notifsModel.dismissAll === "function") {
                                notifsModel.dismissAll();
                            }
                        }
                    }
                }
            }

            // 4. Notifications list (Pixel-style cards)
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                KDEConnect.NotificationsModel {
                    id: notifsModel
                    deviceId: root.deviceId
                }

                // Empty state (all notifications cleared)
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: root.hasDevice && notifsModel.count === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "✓"
                        font.pixelSize: 22
                        color: Qt.rgba(1, 1, 1, 0.35)
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.i18n("All caught up")
                        font.family: "Google Sans Flex"
                        font.pixelSize: 13
                        color: Qt.rgba(1, 1, 1, 0.45)
                    }
                }

                // Disconnected device placeholder
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: !root.hasDevice

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.i18n("No connected phone")
                        font.family: "Google Sans Flex"
                        font.pixelSize: 13
                        color: Qt.rgba(1, 1, 1, 0.45)
                    }
                }

                // Scrollable notifications list
                ListView {
                    id: notifsList
                    anchors.fill: parent
                    clip: true
                    spacing: 8
                    visible: root.hasDevice && notifsModel.count > 0
                    model: notifsModel

                    delegate: PhoneHubNotificationCard {
                        notifModel: model
                        width: notifsList.width
                    }
                }
            }
        }
    }
}

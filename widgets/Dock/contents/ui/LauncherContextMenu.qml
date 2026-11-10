/*
 * SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.plasma5support as Plasma5Support
import "i18n.js" as I18n

Item {
    id: root

    function i18n(k, a1, a2) { return I18n.t(k, a1, a2); }

    property var launcherPopup: null
    property var targetItem: null

    property string appName: ""
    property string launcherUrlStr: ""
    property string storageId: ""
    property bool isPinnedToDock: false
    property bool isHidden: false

    property var onPinRequested: null
    property var onToggleHideRequested: null

    readonly property color cBg: "#1e1e24"
    readonly property color cText: "#E3E3E3"
    readonly property color cHover: Qt.rgba(1, 1, 1, 0.10)
    readonly property color cPress: Qt.rgba(1, 1, 1, 0.16)

    visible: false
    z: 99999

    Plasma5Support.DataSource {
        id: executor
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
        }
        function exec(cmd) {
            var fullCmd = "nohup sh -c " + JSON.stringify(cmd) + " </dev/null >/dev/null 2>&1 & # " + Date.now();
            connectSource(fullCmd);
        }
    }

    function open(item, mousePos, data) {
        targetItem = item;
        appName = data.appName || "";
        launcherUrlStr = data.launcherUrlStr || "";
        storageId = data.storageId || "";
        isPinnedToDock = Boolean(data.isPinnedToDock);
        isHidden = Boolean(data.isHidden);
        onPinRequested = data.onPinRequested || null;
        onToggleHideRequested = data.onToggleHideRequested || null;

        if (launcherPopup) {
            var pos = item.mapToItem(root, mousePos.x, mousePos.y);
            var targetX = pos.x;
            var targetY = pos.y;

            if (targetX + menuCard.width > root.width - 10) {
                targetX = root.width - menuCard.width - 10;
            }
            if (targetX < 10) {
                targetX = 10;
            }

            if (targetY + menuCard.height > root.height - 10) {
                targetY = pos.y - menuCard.height;
            }
            if (targetY < 10) {
                targetY = 10;
            }

            menuCard.x = Math.round(targetX);
            menuCard.y = Math.round(targetY);
        }

        visible = true;
    }

    function close() {
        visible = false;
        targetItem = null;
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: (mouse) => root.close()
    }

    Rectangle {
        id: shadowRect
        x: menuCard.x
        y: menuCard.y + 2
        width: menuCard.width
        height: menuCard.height
        radius: menuCard.radius
        color: Qt.rgba(0, 0, 0, 0.35)
        z: 1
    }

    Rectangle {
        id: menuCard
        z: 2
        width: 190
        height: contentCol.implicitHeight + 12
        radius: 18
        color: root.cBg
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: (mouse) => mouse.accepted = true
        }

        Column {
            id: contentCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 6
            spacing: 2

            // 1. App info
            Rectangle {
                width: parent.width
                height: 38
                radius: 12
                color: infoMouse.pressed ? root.cPress : (infoMouse.containsMouse ? root.cHover : "transparent")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Item {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20

                        Image {
                            id: infoIconImg
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            sourceSize: Qt.size(40, 40)
                            fillMode: Image.PreserveAspectFit
                            source: Qt.resolvedUrl("icons/info.svg")
                            visible: false
                        }

                        MultiEffect {
                            anchors.fill: infoIconImg
                            source: infoIconImg
                            colorization: 1.0
                            colorizationColor: root.cText
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: i18n("App info")
                        font.family: "Google Sans Flex"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: root.cText
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: infoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var dFile = root.storageId || "";
                        if (!dFile && root.launcherUrlStr) {
                            var u = root.launcherUrlStr;
                            if (u.indexOf("applications:") === 0) {
                                dFile = u.replace("applications:", "");
                            } else {
                                var lastSlash = u.lastIndexOf("/");
                                if (lastSlash >= 0) {
                                    dFile = u.substring(lastSlash + 1);
                                }
                            }
                        }
                        if (dFile && dFile.indexOf(".desktop") === -1) {
                            dFile += ".desktop";
                        }

                        if (dFile) {
                            executor.exec("plasma-discover --desktopfile " + JSON.stringify(dFile) + " || plasma-discover || kcmshell6 kcm_app-permissions &");
                        } else {
                            executor.exec("kcmshell6 kcm_app-permissions || systemsettings kcm_app-permissions || plasma-discover &");
                        }
                        root.close();
                    }
                }
            }

            // 2. Pin to taskbar (only when not pinned)
            Rectangle {
                width: parent.width
                height: 38
                radius: 12
                visible: !root.isPinnedToDock
                color: pinMouse.pressed ? root.cPress : (pinMouse.containsMouse ? root.cHover : "transparent")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Item {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20

                        Image {
                            id: pinIconImg
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            sourceSize: Qt.size(40, 40)
                            fillMode: Image.PreserveAspectFit
                            source: Qt.resolvedUrl("icons/keep.svg")
                            visible: false
                        }

                        MultiEffect {
                            anchors.fill: pinIconImg
                            source: pinIconImg
                            colorization: 1.0
                            colorizationColor: root.cText
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: i18n("Pin to Taskbar")
                        font.family: "Google Sans Flex"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: root.cText
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: pinMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.onPinRequested) {
                            root.onPinRequested(root.launcherUrlStr);
                        }
                        root.close();
                    }
                }
            }

            // 3. Hide / Un-hide
            Rectangle {
                width: parent.width
                height: 38
                radius: 12
                color: hideMouse.pressed ? root.cPress : (hideMouse.containsMouse ? root.cHover : "transparent")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Item {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20

                        Image {
                            id: hideIconImg
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            sourceSize: Qt.size(40, 40)
                            fillMode: Image.PreserveAspectFit
                            source: Qt.resolvedUrl("icons/visibility.svg")
                            visible: false
                        }

                        MultiEffect {
                            anchors.fill: hideIconImg
                            source: hideIconImg
                            colorization: 1.0
                            colorizationColor: root.cText
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.isHidden ? i18n("Un-hide") : i18n("Hide")
                        font.family: "Google Sans Flex"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: root.cText
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: hideMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.onToggleHideRequested) {
                            root.onToggleHideRequested(root.launcherUrlStr, root.isHidden);
                        }
                        root.close();
                    }
                }
            }
        }
    }
}

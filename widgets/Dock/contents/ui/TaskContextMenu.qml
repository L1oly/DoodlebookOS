/*
 * SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import "i18n.js" as I18n

PlasmaCore.Dialog {
    id: contextMenuDialog

    function i18n(k, a1, a2) { return I18n.t(k, a1, a2); }

    flags: Qt.WindowStaysOnTopHint
    backgroundHints: PlasmaCore.Types.NoBackground
    location: PlasmaCore.Types.Floating
    visualParent: targetItem
    floating: 10
    hideOnWindowDeactivate: true

    property Item targetItem: null
    property var modelIndex: null
    property var tasksModel: null
    property var dockRoot: null
    property bool isWindow: false
    property bool isLauncher: false
    property bool hasLauncher: false
    property url launcherUrl: ""
    property string appId: ""

    readonly property bool status: visible

    readonly property bool isDark: Kirigami.Theme.colorSet === Kirigami.Theme.Complementary || Kirigami.Theme.backgroundColor.r < 0.5
    readonly property color cBg: mainItem ? mainItem.Kirigami.Theme.backgroundColor : "#19191f"
    readonly property color cBorder: isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color cText: isDark ? "#E3E3E3" : "#1F1F1F"
    readonly property color cHover: isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.07)
    readonly property color cPress: isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.12)

    function open() {
        if (dockRoot && typeof dockRoot.requestHideTooltip === "function") {
            dockRoot.requestHideTooltip(null);
        }
        if (dockRoot && typeof dockRoot.requestHideWindowPreviewImmediately === "function") {
            dockRoot.requestHideWindowPreviewImmediately();
        }

        // If right-clicked on the same item with an open menu -> toggle close
        if (contextMenuDialog.visible && targetItem === visualParent) {
            close();
            return;
        }

        if (dockRoot && typeof dockRoot.registerContextMenu === "function") {
            dockRoot.registerContextMenu(contextMenuDialog);
        }

        // If menu was open for another item -> close immediately to reset popup on KWin/Wayland
        if (contextMenuDialog.visible) {
            contextMenuDialog.visible = false;
        }

        targetItem = visualParent;
        contextMenuDialog.visible = true;
        contextMenuDialog.requestActivate();
    }

    function close() {
        contextMenuDialog.visible = false;
        targetItem = null;
    }

    onActiveChanged: {
        if (!active && visible) {
            close();
        }
    }

    onVisibleChanged: {
        if (!visible) {
            targetItem = null;
        }
    }

    width: mainItem.implicitWidth
    height: mainItem.implicitHeight

    mainItem: Item {
        id: mainItem
        Kirigami.Theme.colorSet: Kirigami.Theme.Tooltip
        Kirigami.Theme.inherit: false
        implicitWidth: 204
        implicitHeight: cardRect.height + 10

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

        scale: contextMenuDialog.visible ? 1.0 : 0.88
        opacity: contextMenuDialog.visible ? 1.0 : 0.0
        transformOrigin: Item.Bottom

        Behavior on scale {
            NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
        }
        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutQuad }
        }

        // Soft drop shadow
        Rectangle {
            x: cardRect.x
            y: cardRect.y + 1
            width: cardRect.width
            height: cardRect.height
            radius: cardRect.radius
            color: Qt.rgba(0, 0, 0, 0.20)
            z: -1
        }

        // Main bubble card
        Rectangle {
            id: cardRect
            x: 0
            y: 0
            width: parent.width
            height: cardColumn.implicitHeight + 12
            radius: 20
            color: contextMenuDialog.cBg
            border.color: "transparent"
            border.width: 0

            Column {
                id: cardColumn
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 6
                spacing: 2

                // 1. "Remove from Taskbar" / "Pin to Taskbar"
                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 14
                    color: pinMouse.pressed ? contextMenuDialog.cPress : (pinMouse.containsMouse ? contextMenuDialog.cHover : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // Pushpin icon (keep / keep_off)
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
                                source: (contextMenuDialog.isLauncher || contextMenuDialog.hasLauncher)
                                    ? Qt.resolvedUrl("icons/keep_off.svg")
                                    : Qt.resolvedUrl("icons/keep.svg")
                                visible: false
                            }

                            MultiEffect {
                                anchors.fill: pinIconImg
                                source: pinIconImg
                                colorization: 1.0
                                colorizationColor: contextMenuDialog.cText
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: (contextMenuDialog.isLauncher || contextMenuDialog.hasLauncher)
                                  ? i18n("Remove from Taskbar")
                                  : i18n("Pin to Taskbar")
                            font.family: "Google Sans Flex"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: contextMenuDialog.cText
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: pinMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (contextMenuDialog.tasksModel) {
                                var targetUrl = (contextMenuDialog.launcherUrl || "").toString();
                                if (!targetUrl && contextMenuDialog.appId) {
                                    var id = contextMenuDialog.appId.toString();
                                    if (!id.endsWith(".desktop")) {
                                        id += ".desktop";
                                    }
                                    targetUrl = "applications:" + id;
                                }
                                if (targetUrl) {
                                    if (contextMenuDialog.isLauncher || contextMenuDialog.hasLauncher) {
                                        contextMenuDialog.tasksModel.requestRemoveLauncher(targetUrl);
                                    } else {
                                        contextMenuDialog.tasksModel.requestAddLauncher(targetUrl);
                                    }
                                }
                            }
                            contextMenuDialog.close();
                        }
                    }
                }

                // 2. "App info"
                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 14
                    color: infoMouse.pressed ? contextMenuDialog.cPress : (infoMouse.containsMouse ? contextMenuDialog.cHover : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // App info icon (info.svg)
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
                                colorizationColor: contextMenuDialog.cText
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: i18n("App info")
                            font.family: "Google Sans Flex"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: contextMenuDialog.cText
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: infoMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            executor.exec("kcmshell6 kcm_app-permissions || systemsettings kcm_app-permissions || plasma-discover &");
                            contextMenuDialog.close();
                        }
                    }
                }

                // 3. Optional: "Close" when running as a window
                Rectangle {
                    width: parent.width
                    height: 1
                    color: contextMenuDialog.cBorder
                    visible: contextMenuDialog.isWindow
                }

                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 14
                    visible: contextMenuDialog.isWindow
                    color: closeMouse.pressed ? contextMenuDialog.cPress : (closeMouse.containsMouse ? contextMenuDialog.cHover : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Text {
                            Layout.preferredWidth: 18
                            horizontalAlignment: Text.AlignHCenter
                            text: "✕"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: contextMenuDialog.cText
                        }

                        Text {
                            Layout.fillWidth: true
                            text: i18n("Close")
                            font.family: "Google Sans Flex"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: contextMenuDialog.cText
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (contextMenuDialog.tasksModel && contextMenuDialog.modelIndex) {
                                contextMenuDialog.tasksModel.requestClose(contextMenuDialog.modelIndex);
                            }
                            contextMenuDialog.close();
                        }
                    }
                }
            }
        }

        // Downward triangular arrow pointing at the center of the taskbar icon
        Shape {
            id: arrowDown
            anchors.fill: parent
            readonly property real midX: Math.round(cardRect.width / 2)

            ShapePath {
                strokeWidth: 0
                fillColor: contextMenuDialog.cBg
                startX: arrowDown.midX - 6
                startY: cardRect.height - 1
                PathLine { x: arrowDown.midX; y: cardRect.height + 7 }
                PathLine { x: arrowDown.midX + 6; y: cardRect.height - 1 }
                PathLine { x: arrowDown.midX - 6; y: cardRect.height - 1 }
            }
        }
    }
}

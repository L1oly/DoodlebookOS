/*
    SPDX-FileCopyrightText: 2019 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2026 DoodlebookOS Team

    SPDX-License-Identifier: LGPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

import org.kde.kirigami as Kirigami

import org.kde.plasma.private.containmentlayoutmanager as ContainmentLayoutManager

ContainmentLayoutManager.ConfigOverlay {
    id: overlay

    LayoutMirroring.enabled: false
    LayoutMirroring.childrenInherit: true

    opacity: open ? 1.0 : 0.0
    Behavior on opacity {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
        }
    }

    readonly property bool isDark: Kirigami.Theme.colorSet === Kirigami.Theme.Complementary || Kirigami.Theme.backgroundColor.r < 0.5
    readonly property color cBg: isDark ? "#282A2E" : "#F0F3F8"
    readonly property color cBorder: isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color cText: isDark ? "#E3E3E3" : "#1F1F1F"
    readonly property color cHover: isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.07)
    readonly property color cPress: isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.12)

    readonly property bool isFolderApplet: {
        var container = overlay.itemContainer;
        return Boolean(container && container.applet && container.applet.plasmoid && (container.applet.plasmoid.pluginName === "org.doodlebookos.appgroup" || container.applet.plasmoid.pluginName === "org.doodlebookos.folder"));
    }

    readonly property bool isConfigurableApplet: {
        var container = overlay.itemContainer;
        if (!container || !container.applet || !container.applet.plasmoid) return false;
        var pName = container.applet.plasmoid.pluginName || "";
        if (pName === "org.doodlebookos.appgroup" || pName === "org.doodlebookos.folder" || pName === "org.doodlebookos.clock" || pName === "org.doodlebookos.upnext") {
            return false;
        }
        var act = container.applet.plasmoid.internalAction("configure");
        return Boolean(act && act.enabled);
    }

    SequentialAnimation {
        id: removeAnim

        NumberAnimation {
            target: overlay.itemContainer
            property: "scale"
            from: 1
            to: 0
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
        }
        ScriptAction {
            script: {
                var container = overlay.itemContainer;
                if (container && container.applet) {
                    container.applet.plasmoid.internalAction("remove").trigger();
                    container.editMode = false;
                }
            }
        }
    }

    // Touch support for pinch-to-resize and touch drag
    MultiPointTouchArea {
        anchors.fill: parent
        property real previousMinX
        property real previousMinY
        property real previousMaxX
        property real previousMaxY
        property bool pinching: false
        mouseEnabled: false
        maximumTouchPoints: 2
        touchPoints: [
            TouchPoint { id: point1 },
            TouchPoint { id: point2 }
        ]

        onPressed: {
            overlay.itemContainer.layout.releaseSpace(overlay.itemContainer);
            previousMinX = point1.sceneX;
            previousMinY = point1.sceneY;
        }

        onUpdated: {
            let minX;
            let minY;
            let maxX;
            let maxY;

            if (point1.pressed && point2.pressed) {
                minX = Math.min(point1.sceneX, point2.sceneX);
                minY = Math.min(point1.sceneY, point2.sceneY);
                maxX = Math.max(point1.sceneX, point2.sceneX);
                maxY = Math.max(point1.sceneY, point2.sceneY);
            } else {
                minX = point1.pressed ? point1.sceneX : point2.sceneX;
                minY = point1.pressed ? point1.sceneY : point2.sceneY;
                maxX = -1;
                maxY = -1;
            }

            if (pinching === (point1.pressed && point2.pressed)) {
                overlay.itemContainer.x += minX - previousMinX;
                overlay.itemContainer.y += minY - previousMinY;

                if (pinching && !overlay.isFolderApplet) {
                    overlay.itemContainer.width += maxX - previousMaxX + previousMinX - minX;
                    overlay.itemContainer.height += maxY - previousMaxY + previousMinY - minY;
                }
                overlay.itemContainer.layout.showPlaceHolderForItem(overlay.itemContainer);
            }

            pinching = point1.pressed && point2.pressed;
            previousMinX = minX;
            previousMinY = minY;
            previousMaxX = maxX;
            previousMaxY = maxY;
        }
        onReleased: {
            if (point1.pressed || point2.pressed) {
                return;
            }
            overlay.itemContainer.layout.positionItem(overlay.itemContainer);
            overlay.itemContainer.layout.hidePlaceHolder();
            pinching = false;
        }
        onCanceled: released()
    }

    // Mouse drag area to move/reposition the widget on the desktop
    MouseArea {
        id: bodyDragArea
        anchors.fill: parent
        anchors.margins: 4
        drag.target: overlay.itemContainer
        cursorShape: containsPress ? Qt.DragMoveCursor : Qt.OpenHandCursor
        hoverEnabled: true
        z: 10
        onPressed: mouse => {
            if (mouse.button === Qt.LeftButton) {
                overlay.itemContainer.layout.releaseSpace(overlay.itemContainer);
            }
        }
        onPositionChanged: mouse => {
            if (!pressed || mouse.buttons !== Qt.LeftButton) return;
            overlay.itemContainer.layout.showPlaceHolderForItem(overlay.itemContainer);
            var dragPos = mapToItem(overlay.itemContainer, mouse.x, mouse.y);
            overlay.itemContainer.userDrag(Qt.point(overlay.itemContainer.x, overlay.itemContainer.y), dragPos);
        }
        onReleased: mouse => {
            overlay.itemContainer.layout.hidePlaceHolder();
            overlay.itemContainer.layout.positionItem(overlay.itemContainer);
        }
    }

    // Pink circular resize handles (flat, 12x12, radius 6, #F48FB1)
    component PinkResizeHandle: ContainmentLayoutManager.ResizeHandle {
        id: handle
        width: 12
        height: 12
        z: 999
        visible: !overlay.isFolderApplet

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: "#F48FB1"
        }
        scale: (overlay.open && !overlay.isFolderApplet) ? 1 : 0
        Behavior on scale {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }
    }

    PinkResizeHandle {
        resizeCorner: ContainmentLayoutManager.ResizeHandle.TopLeft
        anchors {
            horizontalCenter: parent.left
            verticalCenter: parent.top
        }
    }
    PinkResizeHandle {
        resizeCorner: ContainmentLayoutManager.ResizeHandle.Left
        anchors {
            horizontalCenter: parent.left
            verticalCenter: parent.verticalCenter
        }
    }
    PinkResizeHandle {
        resizeCorner: ContainmentLayoutManager.ResizeHandle.BottomLeft
        anchors {
            horizontalCenter: parent.left
            verticalCenter: parent.bottom
        }
    }
    PinkResizeHandle {
        resizeCorner: ContainmentLayoutManager.ResizeHandle.Bottom
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.bottom
        }
    }
    PinkResizeHandle {
        resizeCorner: ContainmentLayoutManager.ResizeHandle.BottomRight
        anchors {
            horizontalCenter: parent.right
            verticalCenter: parent.bottom
        }
    }
    PinkResizeHandle {
        resizeCorner: ContainmentLayoutManager.ResizeHandle.Right
        anchors {
            horizontalCenter: parent.right
            verticalCenter: parent.verticalCenter
        }
    }
    PinkResizeHandle {
        resizeCorner: ContainmentLayoutManager.ResizeHandle.TopRight
        anchors {
            horizontalCenter: parent.right
            verticalCenter: parent.top
        }
    }
    PinkResizeHandle {
        resizeCorner: ContainmentLayoutManager.ResizeHandle.Top
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.top
        }
    }

    // Material 3 Speech-Bubble Remove/Configure Menu pointing up at the bottom handle
    Item {
        id: removeBubble
        anchors.top: parent.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: overlay.isConfigurableApplet ? 158 : 120
        height: 46
        z: 9999

        opacity: overlay.open ? 1.0 : 0.0
        scale: overlay.open ? 1.0 : 0.86
        transformOrigin: Item.Top

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }
        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutBack }
        }

        // Soft drop shadow
        Rectangle {
            x: bubbleBody.x
            y: bubbleBody.y + 1
            width: bubbleBody.width
            height: bubbleBody.height
            radius: bubbleBody.radius
            color: Qt.rgba(0, 0, 0, 0.18)
            z: -1
        }

        // Upward triangular pointer pointing up to the bottom handle
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: 0
                fillColor: overlay.cBg
                startX: Math.round(removeBubble.width / 2) - 6
                startY: 7
                PathLine { x: Math.round(removeBubble.width / 2); y: 0 }
                PathLine { x: Math.round(removeBubble.width / 2) + 6; y: 7 }
                PathLine { x: Math.round(removeBubble.width / 2) - 6; y: 7 }
            }
        }

        // Main pill body
        Rectangle {
            id: bubbleBody
            x: 0
            y: 7
            width: parent.width
            height: 38
            radius: 19
            color: overlay.cBg
            border.color: overlay.cBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 2
                spacing: 2

                // Configure button (only for configurable applets like Weather)
                Rectangle {
                    visible: overlay.isConfigurableApplet
                    Layout.preferredWidth: 34
                    Layout.fillHeight: true
                    radius: 17
                    color: configBtnMouse.pressed ? overlay.cPress : (configBtnMouse.containsMouse ? overlay.cHover : "transparent")

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        source: Qt.resolvedUrl("icons/settings.svg")
                        isMask: true
                        color: overlay.cText
                    }

                    MouseArea {
                        id: configBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var container = overlay.itemContainer;
                            if (container && container.applet && container.applet.plasmoid) {
                                var act = container.applet.plasmoid.internalAction("configure");
                                if (act) act.trigger();
                                container.editMode = false;
                            }
                        }
                    }
                }

                Rectangle {
                    visible: overlay.isConfigurableApplet
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 18
                    Layout.alignment: Qt.AlignVCenter
                    color: overlay.cBorder
                }

                // Remove button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 17
                    color: removeBtnMouse.pressed ? overlay.cPress : (removeBtnMouse.containsMouse ? overlay.cHover : "transparent")

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "✕"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: overlay.cText
                        }

                        Text {
                            text: i18n("Remove")
                            font.family: "Google Sans Flex"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: overlay.cText
                        }
                    }

                    MouseArea {
                        id: removeBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            removeAnim.restart();
                        }
                    }
                }
            }
        }
    }
}

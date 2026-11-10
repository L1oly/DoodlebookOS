/*
 * SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: phoneHubBtn

    property bool active: false
    property real buttonHeight: 52
    property bool isVertical: false
    signal clicked()
    signal rightClicked(var mouse)

    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1.0
    readonly property real effectiveBase: phoneHubBtn.isVertical ? phoneHubBtn.width : phoneHubBtn.buttonHeight
    function snap(val) {
        return Math.round(val * dpr) / dpr;
    }

    readonly property real capsuleHeight: snap(effectiveBase * 0.73)
    readonly property real capsuleWidth: snap(effectiveBase * 0.86)
    readonly property real capsuleTopMargin: snap(effectiveBase * 0.12)
    readonly property real iconSize: snap(effectiveBase * 0.37)

    implicitWidth: phoneHubBtn.isVertical ? phoneHubBtn.buttonHeight : phoneHubBtn.capsuleWidth
    implicitHeight: phoneHubBtn.isVertical ? phoneHubBtn.capsuleWidth : phoneHubBtn.buttonHeight
    width: phoneHubBtn.implicitWidth
    height: phoneHubBtn.implicitHeight
    Layout.preferredWidth: phoneHubBtn.implicitWidth
    Layout.preferredHeight: phoneHubBtn.implicitHeight
    Layout.alignment: Qt.AlignVCenter

    readonly property bool isDarkTheme: Kirigami.Theme.textColor.r > 0.5 || Kirigami.Theme.textColor.g > 0.5 || Kirigami.Theme.textColor.b > 0.5

    Rectangle {
        id: capsuleBg
        y: phoneHubBtn.capsuleTopMargin
        anchors.horizontalCenter: parent.horizontalCenter
        width: phoneHubBtn.isVertical ? phoneHubBtn.capsuleHeight : phoneHubBtn.capsuleWidth
        height: phoneHubBtn.isVertical ? phoneHubBtn.capsuleWidth : phoneHubBtn.capsuleHeight
        radius: (phoneHubBtn.isVertical ? phoneHubBtn.capsuleWidth : phoneHubBtn.capsuleHeight) / 2

        Kirigami.Theme.colorSet: Kirigami.Theme.Header
        Kirigami.Theme.inherit: false
        readonly property color baseColor: Kirigami.Theme.backgroundColor
        readonly property color activeColor: Kirigami.Theme.highlightColor
        readonly property color activeIconColor: Kirigami.Theme.highlightedTextColor

        color: {
            if (phoneHubBtn.active) {
                return mouseArea.pressed ? Qt.darker(activeColor, 1.1) : activeColor;
            }
            if (mouseArea.pressed) {
                return Qt.lighter(baseColor, 1.35);
            }
            if (mouseArea.containsMouse) {
                return Qt.lighter(baseColor, 1.15);
            }
            return baseColor;
        }

        border.color: {
            if (phoneHubBtn.active) {
                return activeColor;
            }
            return phoneHubBtn.isDarkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04);
        }
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Kirigami.Icon {
            id: coloredIcon
            anchors.centerIn: parent
            width: phoneHubBtn.iconSize
            height: phoneHubBtn.iconSize
            source: Qt.resolvedUrl("icons/phone_hub.svg")
            isMask: true
            color: phoneHubBtn.active ? capsuleBg.activeIconColor : Kirigami.Theme.textColor
            roundToIconSize: false

            Behavior on scale {
                NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                mouse.accepted = true;
            }
        }
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                phoneHubBtn.rightClicked(mouse);
            } else {
                phoneHubBtn.clicked();
            }
        }
    }
}

/*
 * SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Shapes
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmaCore.Dialog {
    id: tooltipDialog

    type: PlasmaCore.Dialog.Tooltip
    flags: Qt.ToolTip | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
    backgroundHints: PlasmaCore.Types.NoBackground
    location: PlasmaCore.Types.Floating
    visualParent: targetItem
    floating: 10

    property Item targetItem: null
    property string text: ""
    property real dockHeight: 52
    property color panelBgColor: Kirigami.Theme.backgroundColor
    property color panelTextColor: Kirigami.Theme.textColor

    width: mainItem.implicitWidth
    height: mainItem.implicitHeight

    readonly property bool isDarkTheme: Kirigami.Theme.textColor.r > 0.5 || Kirigami.Theme.textColor.g > 0.5 || Kirigami.Theme.textColor.b > 0.5
    readonly property color bubbleColor: {
        if (panelBgColor && panelBgColor.a > 0 && panelBgColor !== "#00000000") {
            return panelBgColor;
        }
        return isDarkTheme ? "#2A2E32" : "#F4F4F8";
    }
    readonly property color textColor: {
        if (panelTextColor && panelTextColor.a > 0 && panelTextColor !== "#00000000") {
            return panelTextColor;
        }
        return isDarkTheme ? "#F4F4F8" : "#1F1F24";
    }

    function requestShow(item, tooltipText) {
        if (!item || !tooltipText || tooltipText.length === 0) {
            requestHideImmediately();
            return;
        }

        if (hideGraceTimer && hideGraceTimer.running) {
            hideGraceTimer.stop();
        }

        targetItem = item;
        tooltipDialog.visualParent = item;
        text = tooltipText;
        if (mainItem) {
            mainItem.opacity = 1;
        }
        tooltipDialog.visible = true;
    }

    function requestHide(item) {
        if (!item) {
            requestHideImmediately();
            return;
        }
        if (targetItem === item) {
            if (hideGraceTimer) {
                hideGraceTimer.restart();
            } else {
                requestHideImmediately();
            }
        }
    }

    function requestHideImmediately() {
        if (hideGraceTimer && hideGraceTimer.running) {
            hideGraceTimer.stop();
        }
        if (mainItem) {
            mainItem.opacity = 0;
        }
        tooltipDialog.visible = false;
        targetItem = null;
        tooltipDialog.visualParent = null;
    }

    mainItem: Item {
        id: mainItem
        implicitWidth: Math.max(48, label.implicitWidth + 28)
        implicitHeight: 34
        opacity: 1

        Timer {
            id: hideGraceTimer
            interval: 60
            repeat: false
            onTriggered: {
                tooltipDialog.requestHideImmediately();
            }
        }

        // Main rounded pill body - flat, borderless
        Rectangle {
            id: bubbleBody
            x: 0
            y: 0
            width: parent.width
            height: 28
            radius: 14
            color: tooltipDialog.bubbleColor
            border.width: 0

            Text {
                id: label
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: tooltipDialog.text
                color: tooltipDialog.textColor
                font.pixelSize: 12
                font.weight: Font.Medium
                renderType: Text.NativeRendering
            }
        }

        // Downward triangular pointer / arrow pointing at the icon
        Shape {
            id: arrowShape
            anchors.fill: parent
            containsMode: Shape.FillContains
            readonly property real midX: Math.round(width / 2)

            ShapePath {
                strokeWidth: 0
                fillColor: tooltipDialog.bubbleColor

                startX: arrowShape.midX - 6
                startY: 27

                PathLine { x: arrowShape.midX; y: 33 }
                PathLine { x: arrowShape.midX + 6; y: 27 }
                PathLine { x: arrowShape.midX - 6; y: 27 }
            }
        }
    }
}

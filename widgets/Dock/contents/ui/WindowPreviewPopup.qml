/*
 * SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.pipewire as PipeWire
import org.kde.taskmanager as TaskManager

PlasmaCore.Dialog {
    id: previewDialog

    flags: Qt.WindowStaysOnTopHint
    backgroundHints: PlasmaCore.Types.NoBackground
    location: PlasmaCore.Types.Floating
    visualParent: null
    hideOnWindowDeactivate: true

    readonly property int calculatedWidth: {
        var c = Math.max(1, childCount);
        var rowW = c * 196 + Math.max(0, c - 1) * 12;
        return Math.min(Screen.desktopAvailableWidth - 32, rowW + 28) + 8;
    }
    readonly property int calculatedHeight: 150

    width: calculatedWidth
    height: calculatedHeight
    onCalculatedWidthChanged: updatePosition()

    function updatePosition() {
        if (!targetItem) return;
        var scr = (targetItem.Screen) ? targetItem.Screen : Screen;
        var scrWidth = scr.width > 0 ? scr.width : 1920;
        var scrHeight = scr.height > 0 ? scr.height : 1080;
        var scrX = (scr.virtualX !== undefined) ? scr.virtualX : 0;
        var scrY = (scr.virtualY !== undefined) ? scr.virtualY : 0;

        var effPanelHeight = previewDialog.dockHeight > 0 ? previewDialog.dockHeight : 52;
        if (targetItem.Window && targetItem.Window.window && targetItem.Window.window.height > 0) {
            effPanelHeight = targetItem.Window.window.height;
        }

        var bottomGap = 4;
        var currentW = previewDialog.calculatedWidth;
        var currentH = previewDialog.calculatedHeight;
        var panelTop = scrY + scrHeight - effPanelHeight;

        var iconGlobalY = 0;
        if (typeof targetItem.mapToGlobal === "function") {
            try {
                var gTop = targetItem.mapToGlobal(0, 0);
                if (gTop && gTop.y !== undefined && gTop.y > 0) {
                    iconGlobalY = gTop.y;
                }
            } catch (eY) {}
        }

        var targetY = (iconGlobalY > 0)
            ? Math.max(24, Math.round(iconGlobalY - currentH - bottomGap))
            : Math.max(24, Math.round(panelTop - currentH - bottomGap));

        var btnCenterX = 0;
        if (typeof targetItem.mapToGlobal === "function") {
            try {
                var gPt = targetItem.mapToGlobal(targetItem.width / 2, 0);
                if (gPt && gPt.x !== undefined && gPt.x > 0) {
                    btnCenterX = gPt.x;
                }
            } catch (e) {}
        }
        if (btnCenterX === 0 && typeof targetItem.mapToItem === "function") {
            try {
                var lPt = targetItem.mapToItem(null, targetItem.width / 2, 0);
                var winX = (targetItem.Window && targetItem.Window.window) ? targetItem.Window.window.x : 0;
                btnCenterX = winX + lPt.x;
            } catch (e2) {}
        }

        var targetX = btnCenterX > 0
            ? Math.round(btnCenterX - currentW / 2)
            : (scrX + Math.round((scrWidth - currentW) / 2));
        targetX = Math.max(scrX + 16, Math.min(scrX + scrWidth - currentW - 16, targetX));

        previewDialog.x = targetX;
        previewDialog.y = targetY;
    }

    onVisibleChanged: {
        if (!visible) {
            cancelHideTimer();
            targetItem = null;
            taskIndex = -1;
            childCount = 0;
            winIdList = [];
            hoveredCardIndex = -1;
        }
    }

    property Item targetItem: null
    property var tasksModel: null
    property int taskIndex: -1
    property int childCount: 0
    property string appName: ""
    property var fallbackIcon: null
    property var winIdList: []
    property real dockHeight: 52

    property int hoveredCardIndex: -1
    property color panelBgColor: Kirigami.Theme.backgroundColor
    property color panelTextColor: Kirigami.Theme.textColor

    readonly property bool isDarkTheme: Kirigami.Theme.textColor.r > 0.5 || Kirigami.Theme.textColor.g > 0.5 || Kirigami.Theme.textColor.b > 0.5
    readonly property color cardBgColor: {
        if (panelBgColor && panelBgColor.a > 0 && panelBgColor !== "#00000000") {
            return panelBgColor;
        }
        return isDarkTheme ? "#2A2E33" : "#F0F2F5";
    }

    function requestShow(item, index, count, name, icon, winIds) {
        if (!item || count <= 1 || index < 0) {
            requestHideImmediately();
            return;
        }

        cancelHideTimer();

        taskIndex = index;
        childCount = count;
        appName = name || "";
        fallbackIcon = icon || null;
        winIdList = (winIds && winIds.length > 0) ? winIds : [];
        targetItem = item;

        previewDialog.width = previewDialog.calculatedWidth;
        previewDialog.height = previewDialog.calculatedHeight;
        updatePosition();

        previewDialog.visible = true;
        mainItem.animatedOpacity = 1.0;
        mainItem.animatedYOffset = 0.0;
    }

    function startHideTimer() {
        if (mainItem && mainItem.hideTimer) {
            mainItem.hideTimer.restart();
        }
    }

    function cancelHideTimer() {
        if (mainItem && mainItem.hideTimer) {
            mainItem.hideTimer.stop();
        }
    }

    function requestHide(item) {
        if (!item || targetItem === item) {
            startHideTimer();
        }
    }

    function requestHideImmediately() {
        cancelHideTimer();
        mainItem.animatedOpacity = 0.0;
        mainItem.animatedYOffset = 4.0;
        previewDialog.visible = false;
        targetItem = null;
        previewDialog.visualParent = null;
        taskIndex = -1;
        childCount = 0;
        winIdList = [];
        hoveredCardIndex = -1;
    }

    function requestActivateWindow(childIdx) {
        if (tasksModel && taskIndex >= 0) {
            var pIdx = tasksModel.makeModelIndex(taskIndex);
            if (pIdx) {
                var cIdx = tasksModel.index(childIdx, 0, pIdx);
                if (cIdx) {
                    tasksModel.requestActivate(cIdx);
                }
            }
        }
        requestHideImmediately();
    }

    function requestCloseWindow(childIdx) {
        if (tasksModel && taskIndex >= 0) {
            var pIdx = tasksModel.makeModelIndex(taskIndex);
            if (pIdx) {
                var cIdx = tasksModel.index(childIdx, 0, pIdx);
                if (cIdx) {
                    tasksModel.requestClose(cIdx);
                }
            }
        }
    }

    function refreshChildren() {
        if (!targetItem || taskIndex < 0 || !tasksModel) return;
        var pIdx = tasksModel.makeModelIndex(taskIndex);
        if (!pIdx) {
            requestHideImmediately();
            return;
        }
        var count = tasksModel.data(pIdx, TaskManager.AbstractTasksModel.ChildCount) || 0;
        if (count <= 1) {
            requestHideImmediately();
            return;
        }
        childCount = count;
        var winIds = tasksModel.data(pIdx, TaskManager.AbstractTasksModel.WinIdList);
        if (winIds) {
            winIdList = winIds;
        }
    }

    mainItem: Item {
        id: mainItem
        width: previewDialog.calculatedWidth
        height: previewDialog.calculatedHeight
        implicitWidth: previewDialog.calculatedWidth
        implicitHeight: previewDialog.calculatedHeight

        property alias hideTimer: hideTimer
        property real animatedOpacity: 0.0
        property real animatedYOffset: 4.0

        Timer {
            id: hideTimer
            interval: 450
            repeat: false
            onTriggered: {
                previewDialog.requestHideImmediately();
            }
        }

        Connections {
            target: previewDialog.tasksModel
            ignoreUnknownSignals: true
            function onRowsRemoved() { Qt.callLater(previewDialog.refreshChildren); }
            function onRowsInserted() { Qt.callLater(previewDialog.refreshChildren); }
            function onDataChanged() { Qt.callLater(previewDialog.refreshChildren); }
            function onCountChanged() { Qt.callLater(previewDialog.refreshChildren); }
        }

        Behavior on animatedOpacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
        Behavior on animatedYOffset {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        opacity: animatedOpacity
        transform: Translate { y: mainItem.animatedYOffset }

        // Hover keeper area covering the entire popup bounds and the bridge
        HoverHandler {
            id: mainHoverHandler
            onHoveredChanged: {
                if (hovered) {
                    previewDialog.cancelHideTimer();
                }
            }
        }

        // Soft outer shadow
        Rectangle {
            anchors.fill: cardContainer
            anchors.margins: -1
            radius: 26
            color: Qt.rgba(0, 0, 0, 0.28)
            z: -1
        }

        // Main outer container matching toolbar/panel
        Rectangle {
            id: cardContainer
            anchors.centerIn: parent
            width: previewDialog.calculatedWidth - 8
            height: previewDialog.calculatedHeight - 8
            implicitWidth: width
            implicitHeight: height
            radius: 26
            color: previewDialog.cardBgColor
            border.color: previewDialog.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.10)
            border.width: 1
            clip: rowLayout.implicitWidth + 28 > cardContainer.width

            Flickable {
                id: flickable
                anchors.fill: parent
                anchors.margins: 14
                contentWidth: rowLayout.implicitWidth
                contentHeight: rowLayout.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentWidth > width

                Row {
                    id: rowLayout
                    spacing: 12
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: previewDialog.childCount

                        delegate: Item {
                            id: cardDelegate
                            required property int index

                            readonly property var parentModelIndex: (previewDialog.tasksModel && previewDialog.taskIndex >= 0)
                                ? previewDialog.tasksModel.makeModelIndex(previewDialog.taskIndex)
                                : null

                            readonly property var childModelIndex: (parentModelIndex && previewDialog.tasksModel)
                                ? previewDialog.tasksModel.index(index, 0, parentModelIndex)
                                : null

                            readonly property string winId: {
                                if (previewDialog.winIdList && previewDialog.winIdList.length > index && previewDialog.winIdList[index]) {
                                    return previewDialog.winIdList[index].toString();
                                }
                                if (childModelIndex && previewDialog.tasksModel) {
                                    var list = previewDialog.tasksModel.data(childModelIndex, TaskManager.AbstractTasksModel.WinIdList);
                                    if (list && list.length > 0) return list[0].toString();
                                }
                                return "";
                            }

                            readonly property string childTitle: {
                                if (childModelIndex && previewDialog.tasksModel) {
                                    var t = previewDialog.tasksModel.data(childModelIndex, Qt.DisplayRole);
                                    if (t && t.length > 0) return t;
                                }
                                return previewDialog.appName;
                            }

                            readonly property var childIcon: {
                                if (childModelIndex && previewDialog.tasksModel) {
                                    var ic = previewDialog.tasksModel.data(childModelIndex, Qt.DecorationRole);
                                    if (ic) return ic;
                                }
                                return previewDialog.fallbackIcon;
                            }

                            readonly property bool isCardHovered: previewDialog.hoveredCardIndex === index

                            width: 196
                            height: 122

                            HoverHandler {
                                id: cardHoverHandler
                                onHoveredChanged: {
                                    if (hovered) {
                                        previewDialog.cancelHideTimer();
                                        previewDialog.hoveredCardIndex = cardDelegate.index;
                                    } else {
                                        if (previewDialog.hoveredCardIndex === cardDelegate.index) {
                                            previewDialog.hoveredCardIndex = -1;
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: thumbMask
                                width: thumbnailWrapper.width
                                height: thumbnailWrapper.height
                                radius: 14
                                color: "black"
                                visible: false
                                layer.enabled: true
                            }

                            // Inner thumbnail container with rounded corner clipping
                            Item {
                                id: thumbnailWrapper
                                anchors.fill: parent

                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    maskEnabled: true
                                    maskSource: thumbMask
                                }

                                // Dark background filling the card
                                Rectangle {
                                    anchors.fill: parent
                                    color: "#181A1D"
                                }

                                // Fallback icon and title if PipeWire stream is not ready
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    width: parent.width - 24
                                    opacity: pipeWireSourceItem.ready ? 0.0 : 1.0
                                    visible: opacity > 0
                                    z: 0

                                    Behavior on opacity {
                                        NumberAnimation { duration: 150 }
                                    }

                                    Kirigami.Icon {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 36
                                        height: 36
                                        source: cardDelegate.childIcon || "application-x-executable"
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        text: cardDelegate.childTitle
                                        color: Qt.rgba(1, 1, 1, 0.90)
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        renderType: Text.NativeRendering
                                    }
                                }

                                // Live PipeWire thumbnail
                                PipeWire.PipeWireSourceItem {
                                    id: pipeWireSourceItem
                                    anchors.fill: parent
                                    nodeId: screencastingRequest.nodeId
                                    z: 1

                                    opacity: ready ? 1.0 : 0.0

                                    Behavior on opacity {
                                        NumberAnimation { duration: 150 }
                                    }
                                }

                                TaskManager.ScreencastingRequest {
                                    id: screencastingRequest
                                    uuid: cardDelegate.winId
                                }
                            }

                            // Selection highlight white border — ONLY shown when hovered
                            Rectangle {
                                anchors.fill: parent
                                radius: 14
                                color: "transparent"
                                border.width: cardDelegate.isCardHovered ? 2.5 : 0
                                border.color: cardDelegate.isCardHovered ? "#FFFFFF" : "transparent"
                                z: 10

                                Behavior on border.color {
                                    ColorAnimation { duration: 100 }
                                }
                                Behavior on border.width {
                                    NumberAnimation { duration: 100 }
                                }
                            }

                            // Card Click MouseArea
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onEntered: {
                                    previewDialog.cancelHideTimer();
                                    previewDialog.hoveredCardIndex = cardDelegate.index;
                                }
                                onExited: {
                                    if (previewDialog.hoveredCardIndex === cardDelegate.index) {
                                        previewDialog.hoveredCardIndex = -1;
                                    }
                                }
                                onClicked: {
                                    previewDialog.requestActivateWindow(cardDelegate.index);
                                }
                            }

                            // Close Button (X) at top right
                            Rectangle {
                                id: closeBtn
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 7
                                width: 22
                                height: 22
                                radius: 11
                                color: closeHover.hovered ? "#E8EAED" : "#FFFFFF"
                                z: 25

                                // Soft drop shadow under white button
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: -1
                                    radius: 12
                                    color: Qt.rgba(0, 0, 0, 0.28)
                                    z: -1
                                }

                                Text {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: -0.5
                                    text: "✕"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: "#1F1F24"
                                    renderType: Text.NativeRendering
                                }

                                HoverHandler {
                                    id: closeHover
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        previewDialog.requestCloseWindow(cardDelegate.index);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Hover bridge spanning from bottom of cardContainer to bottom of dialog
        // This bridges the gap between popup and dock so mouse never drops out during movement
        Item {
            id: hoverBridge
            anchors.top: cardContainer.bottom
            anchors.bottom: parent.bottom
            anchors.left: cardContainer.left
            anchors.right: cardContainer.right
        }
    }
}

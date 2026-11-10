/*
    SPDX-FileCopyrightText: 2026 DoodlebookOS
    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool isExpanding: Boolean(Plasmoid.configuration.expanding !== false)
    readonly property int customLength: (Plasmoid.configuration.length > 0) ? Plasmoid.configuration.length : 32

    Layout.fillWidth: !isVertical && isExpanding
    Layout.fillHeight: isVertical && isExpanding
    Layout.preferredWidth: isVertical ? (parent ? parent.width : 52) : (isExpanding ? -1 : customLength)
    Layout.preferredHeight: isVertical ? (isExpanding ? -1 : customLength) : (parent ? parent.height : 52)
    Layout.minimumWidth: isVertical ? 1 : (isExpanding ? 1 : customLength)
    Layout.minimumHeight: isVertical ? (isExpanding ? 1 : customLength) : 1

    implicitWidth: isVertical ? (parent ? parent.width : 52) : (isExpanding ? 0 : customLength)
    implicitHeight: isVertical ? (isExpanding ? 0 : customLength) : (parent ? parent.height : 52)

    readonly property bool isTop: Plasmoid.location === PlasmaCore.Types.TopEdge || (Plasmoid.containment && Plasmoid.containment.location === PlasmaCore.Types.TopEdge)
    readonly property bool isBottom: Plasmoid.location === PlasmaCore.Types.BottomEdge || (Plasmoid.containment && Plasmoid.containment.location === PlasmaCore.Types.BottomEdge)

    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    TaskManager.TasksModel {
        id: maximizedTasksModel

        activity: Plasmoid.containment ? Plasmoid.containment.activity : ""
        filterByActivity: true
        screenGeometry: Plasmoid.containment ? Plasmoid.containment.screenGeometry : Qt.rect(0, 0, 0, 0)
        filterByScreen: true
        filterMinimized: true
        filterNotMaximized: true

        Component.onCompleted: {
            if (maximizedTasksModel.hasOwnProperty("filterByCurrentVirtualDesktop")) {
                maximizedTasksModel.filterByCurrentVirtualDesktop = true;
            } else {
                maximizedTasksModel.virtualDesktop = Qt.binding(() => virtualDesktopInfo.currentDesktop);
                maximizedTasksModel.filterByVirtualDesktop = true;
            }
        }
    }

    readonly property bool hasMaximizedWindow: root.isTop && maximizedTasksModel.count > 0

    onParentChanged: {
        if (root.parent && root.isTop) {
            setupOverlayTimer.restart();
        }
    }

    Timer {
        id: setupOverlayTimer
        interval: 10
        repeat: false
        onTriggered: {
            if (!root.isTop) return;
            var candidate = root.parent;
            while (candidate && candidate.parent) {
                candidate = candidate.parent;
            }
            if (candidate) {
                topBarBackgroundOverlay.parent = candidate;
                topBarBackgroundOverlay.anchors.fill = candidate;
            }
        }
    }

    Item {
        id: topBarBackgroundOverlay
        visible: root.isTop
        z: -9999

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.hasMaximizedWindow ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Component.onCompleted: {
        if (Plasmoid.containment && typeof Plasmoid.containment.setContainmentActions === "function") {
            Plasmoid.containment.setContainmentActions("RightButton;NoModifier", "");
        }
        if (root.parent && root.isTop) {
            setupOverlayTimer.restart();
        }
    }

    Item {
        id: clickAnchorItem
        width: 1
        height: 1
    }

    TaskbarContextMenu {
        id: taskbarContextMenu
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                mouse.accepted = true;
            }
        }
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                mouse.accepted = true;
                if (root.isBottom) {
                    clickAnchorItem.x = mouse.x;
                    clickAnchorItem.y = mouse.y;
                    taskbarContextMenu.requestShow(clickAnchorItem);
                }
            }
        }
    }
}

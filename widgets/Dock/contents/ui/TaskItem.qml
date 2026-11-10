/*
 * SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

Item {
    id: taskItem

    required property var model
    required property int index
    property var tasksModel: null
    property var dockRoot: null

    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1.0
    property real dockHeight: 52

    function snap(val) {
        return Math.round(val * dpr) / dpr;
    }

    readonly property real iconSize: snap(dockHeight * 0.70)
    readonly property real iconTopMargin: snap(dockHeight * 0.12)
    readonly property real separatorGap: snap(dockHeight * 0.48)
    readonly property real separatorWidth: Math.max(1 / dpr, snap(dockHeight * 0.05))
    readonly property real separatorHeight: snap(dockHeight * 0.37)
    readonly property real separatorBottomMargin: snap(dockHeight * 0.33)
    readonly property real indicatorHeight: Math.max(1 / dpr, snap(dockHeight * 0.03))
    readonly property real indicatorBottomMargin: snap(dockHeight * 0.05)

    readonly property bool isWindow: model ? Boolean(model.IsWindow) : false
    readonly property bool isLauncher: model ? Boolean(model.IsLauncher) : false
    readonly property bool hasLauncher: model ? Boolean(model.HasLauncher) : false
    readonly property bool isActive: model ? Boolean(model.IsActive) : false
    readonly property bool isMinimized: model ? Boolean(model.IsMinimized) : false
    readonly property bool isMaximized: model ? Boolean(model.IsMaximized) : false
    readonly property string appName: model ? (model.AppName || model.display || "").toString() : ""
    readonly property url launcherUrl: model ? (model.LauncherUrl || "").toString() : ""
    readonly property string appId: model ? (model.AppId || "").toString() : ""

    readonly property bool isGroup: model ? Boolean(model.IsGroupParent) : false
    readonly property int childCount: model ? (model.ChildCount || 0) : 0

    readonly property bool isDarkTheme: Kirigami.Theme.textColor.r > 0.5 || Kirigami.Theme.textColor.g > 0.5 || Kirigami.Theme.textColor.b > 0.5
    readonly property real baseInactiveWidth: snap(dockHeight * 0.13)
    readonly property real baseActiveWidth: snap(dockHeight * 0.22)

    readonly property bool isDemandingAttention: {
        if (!model) return false;
        if (Boolean(model.IsDemandingAttention)) return true;
        var isGroup = Boolean(model.IsGroupParent);
        var childCount = model.ChildCount || 0;
        if (isGroup && childCount > 0 && tasksModel && typeof tasksModel.makeModelIndex === "function") {
            try {
                var parentIdx = tasksModel.makeModelIndex(index);
                if (parentIdx) {
                    for (var c = 0; c < childCount; ++c) {
                        var cIdx = tasksModel.index(c, 0, parentIdx);
                        if (cIdx && Boolean(tasksModel.data(cIdx, TaskManager.AbstractTasksModel.IsDemandingAttention))) {
                            return true;
                        }
                    }
                }
            } catch (e) {}
        }
        return false;
    }

    readonly property bool hasNotification: {
        var _ = dockRoot ? dockRoot.notificationEpoch : 0;
        return dockRoot && typeof dockRoot.hasNotificationForApp === "function"
            ? dockRoot.hasNotificationForApp(taskItem.appId, taskItem.appName, taskItem.launcherUrl)
            : false;
    }

    readonly property bool showAttentionBadge: isDemandingAttention || hasNotification

    readonly property bool isUnpinnedTask: isWindow && !hasLauncher && !isLauncher

    readonly property bool isFirstUnpinnedTask: {
        if (!isUnpinnedTask) return false;
        if (index === 0) return true;
        if (!tasksModel || typeof tasksModel.makeModelIndex !== "function" || typeof tasksModel.data !== "function") return false;
        try {
            var prevIdx = tasksModel.makeModelIndex(index - 1);
            if (!prevIdx) return false;
            var prevHasLauncher = Boolean(tasksModel.data(prevIdx, TaskManager.AbstractTasksModel.HasLauncher));
            var prevIsLauncher = Boolean(tasksModel.data(prevIdx, TaskManager.AbstractTasksModel.IsLauncher));
            return prevHasLauncher || prevIsLauncher;
        } catch (e) {
            return false;
        }
    }

    readonly property real separatorFullWidth: isFirstUnpinnedTask ? (separatorGap * 2 + separatorWidth - (dockRoot ? dockRoot.slotSpacing : 0)) : 0

    width: implicitWidth
    height: implicitHeight
    implicitWidth: iconSize + separatorFullWidth
    implicitHeight: dockHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.alignment: Qt.AlignVCenter

    property real iconYOffset: 0
    property bool wasActive: false

    z: mouseArea.drag.active ? 100 : 1

    readonly property real targetShiftX: {
        if (!dockRoot || !dockRoot.isDragging || dockRoot.dragSourceIndex < 0 || dockRoot.dragTargetIndex < 0) {
            return 0;
        }
        if (index === dockRoot.dragSourceIndex) {
            return 0;
        }
        var S = dockRoot.dragSourceIndex;
        var T = dockRoot.dragTargetIndex;
        var P = dockRoot.slotPitch;

        if (T < S) {
            // Dragged to the left: items between T and S-1 shift right (+P)
            if (index >= T && index < S) {
                return P;
            }
        } else if (T > S) {
            // Dragged to the right: items between S+1 and T shift left (-P)
            if (index > S && index <= T) {
                return -P;
            }
        }
        return 0;
    }

    property real animatedShiftX: targetShiftX

    Behavior on animatedShiftX {
        enabled: dockRoot && dockRoot.isDragging
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    onTargetShiftXChanged: {
        if (!dockRoot || !dockRoot.isDragging) {
            animatedShiftX = targetShiftX;
        }
    }

    onIsActiveChanged: {
        if (isActive) {
            wasActive = true;
        }
    }

    onIsMinimizedChanged: {
        if (isMinimized && wasActive) {
            wasActive = false;
            triggerMinimizeBounce();
        }
    }

    function triggerMinimizeBounce() {
        if (!minimizeBounceAnimation.running) {
            minimizeBounceAnimation.restart();
        }
    }

    function getModelIndex() {
        if (tasksModel && typeof tasksModel.makeModelIndex === "function") {
            try {
                return tasksModel.makeModelIndex(index);
            } catch (e) {
                return null;
            }
        }
        return null;
    }

    Row {
        anchors.fill: parent
        spacing: 0

        // 1. Separator preceding the first unpinned item
        Item {
            id: unpinnedSeparatorItem
            visible: taskItem.isFirstUnpinnedTask
            width: taskItem.separatorFullWidth
            height: taskItem.dockHeight

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: taskItem.separatorBottomMargin
                anchors.left: parent.left
                anchors.leftMargin: Math.max(0, taskItem.separatorGap - (taskItem.dockRoot ? taskItem.dockRoot.slotSpacing : 0))
                width: taskItem.separatorWidth
                height: taskItem.separatorHeight
                radius: width / 2
                color: taskItem.isDarkTheme ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0, 0, 0, 0.40)
            }
        }

        // 2. The task icon button container (equal width and square icon reservation)
        Item {
            id: buttonContainer
            width: taskItem.iconSize
            height: taskItem.dockHeight

            Item {
                id: dragWrapper
                x: 0
                y: 0
                width: parent.width
                height: parent.height
                z: mouseArea.drag.active ? 100 : 1
                opacity: mouseArea.drag.active ? 0.85 : 1.0
                scale: mouseArea.drag.active ? 1.08 : 1.0

                Behavior on scale {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }

                transform: Translate {
                    x: mouseArea.drag.active ? 0 : taskItem.animatedShiftX
                }

                // Subtle shadow under the lifted dragged icon
                Rectangle {
                    y: iconContainer.y
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: taskItem.iconSize + 6
                    height: taskItem.iconSize + 6
                    radius: 14
                    color: Qt.rgba(0, 0, 0, 0.25)
                    visible: mouseArea.drag.active
                    z: -1
                }

                Rectangle {
                    id: bgRect
                    anchors.fill: parent
                    radius: 12
                    color: mouseArea.pressed ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    // Square container strictly iconSize x iconSize
                    Item {
                        id: iconContainer
                        width: taskItem.iconSize
                        height: taskItem.iconSize
                        y: taskItem.iconTopMargin + taskItem.iconYOffset
                        anchors.horizontalCenter: parent.horizontalCenter
                        clip: false

                        Kirigami.Icon {
                            id: appIcon
                            anchors.fill: parent
                            source: model ? (model.decoration || model.icon || model.AppId || "application-x-executable") : "application-x-executable"
                            roundToIconSize: false
                            scale: mouseArea.pressed ? 0.94 : 1.0

                            Behavior on scale {
                                NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                            }
                        }

                        // Notification / Demanding Attention circular badge (ChromeOS pastel pink with crisp white border)
                        Rectangle {
                            id: attentionBadge
                            objectName: "attentionBadge"
                            visible: opacity > 0
                            z: 10

                            readonly property real badgeSize: Math.max(8, taskItem.snap(taskItem.dockHeight * 0.16))

                            width: badgeSize
                            height: badgeSize
                            radius: badgeSize / 2

                            anchors.top: iconContainer.top
                            anchors.topMargin: 0
                            anchors.right: iconContainer.right
                            anchors.rightMargin: 0

                            color: "#FFD6E9"
                            border.color: "#FFFFFF"
                            border.width: Math.max(1.5, Math.round(badgeSize * 0.12))

                            scale: taskItem.showAttentionBadge ? 1.0 : 0.0
                            opacity: taskItem.showAttentionBadge ? 1.0 : 0.0

                            Behavior on scale {
                                NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.25 }
                            }
                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }
                        }
                    }

                    // Running / Active indicator at bottom edge (ChromeOS style)
                    Rectangle {
                        id: statusIndicator
                        visible: taskItem.isWindow
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: taskItem.indicatorBottomMargin
                        anchors.horizontalCenter: parent.horizontalCenter

                        property real extraWidth: 0
                        width: (taskItem.isActive ? taskItem.baseActiveWidth : taskItem.baseInactiveWidth) + extraWidth
                        height: taskItem.indicatorHeight
                        radius: height / 2

                        color: {
                            if (taskItem.isActive) {
                                return taskItem.isDarkTheme ? Qt.rgba(1, 1, 1, 0.95) : (Kirigami.Theme.highlightColor || "#1F1F24");
                            }
                            return taskItem.isDarkTheme ? Qt.rgba(1, 1, 1, 0.42) : Qt.rgba(0, 0, 0, 0.35);
                        }

                        Behavior on width {
                            enabled: !minimizeBounceAnimation.running
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.ArrowCursor

                drag.target: (taskItem.isLauncher || taskItem.hasLauncher || (taskItem.dockRoot && taskItem.index < taskItem.dockRoot.launcherCount)) ? dragWrapper : null
                drag.axis: Drag.XAxis
                drag.threshold: 5

                property bool wasDragged: false

                onPositionChanged: (mouse) => {
                    if (mouseArea.drag.active) {
                        if (!mouseArea.wasDragged) {
                            mouseArea.wasDragged = true;
                            if (taskItem.dockRoot && typeof taskItem.dockRoot.startDrag === "function") {
                                taskItem.dockRoot.startDrag(taskItem.index);
                            }
                        }
                        if (taskItem.dockRoot && typeof taskItem.dockRoot.updateDragTarget === "function") {
                            taskItem.dockRoot.updateDragTarget(taskItem.index, mouseArea, mouse.x);
                        }
                    }
                }

                onReleased: (mouse) => {
                    if (mouseArea.wasDragged || (taskItem.dockRoot && taskItem.dockRoot.isDragging)) {
                        mouseArea.wasDragged = false;
                        if (taskItem.dockRoot && typeof taskItem.dockRoot.updateDragTarget === "function") {
                            taskItem.dockRoot.updateDragTarget(taskItem.index, mouseArea, mouse.x);
                        }
                        var src = taskItem.dockRoot ? taskItem.dockRoot.dragSourceIndex : -1;
                        var tgt = taskItem.dockRoot ? taskItem.dockRoot.dragTargetIndex : -1;
                        if (taskItem.dockRoot && typeof taskItem.dockRoot.finishDrag === "function") {
                            taskItem.dockRoot.finishDrag(src, tgt);
                        }
                    }
                    dragWrapper.x = 0;
                    dragWrapper.y = 0;
                }

                onCanceled: {
                    if (mouseArea.wasDragged || (taskItem.dockRoot && taskItem.dockRoot.isDragging)) {
                        mouseArea.wasDragged = false;
                        if (taskItem.dockRoot && typeof taskItem.dockRoot.cancelDrag === "function") {
                            taskItem.dockRoot.cancelDrag();
                        }
                    }
                    dragWrapper.x = 0;
                    dragWrapper.y = 0;
                }

                onContainsMouseChanged: {
                    if (containsMouse && !mouseArea.drag.active && !(taskItem.dockRoot && taskItem.dockRoot.isDragging)) {
                        if (!contextMenu.visible && taskItem.appName.length > 0) {
                            if (taskItem.dockRoot && taskItem.dockRoot.requestShowTooltip) {
                                taskItem.dockRoot.requestShowTooltip(buttonContainer, taskItem.appName);
                            }
                        }
                    } else {
                        if (taskItem.dockRoot && taskItem.dockRoot.requestHideTooltip) {
                            taskItem.dockRoot.requestHideTooltip(buttonContainer);
                        }
                    }
                }

                onClicked: (mouse) => {
                    if (wasDragged || Math.abs(dragWrapper.x) > 6) {
                        wasDragged = false;
                        return;
                    }

                    if (taskItem.dockRoot && taskItem.dockRoot.requestHideTooltip) {
                        taskItem.dockRoot.requestHideTooltip(buttonContainer);
                    }

                    var idx = taskItem.getModelIndex();
                    if (!idx) return;
                    if (mouse.button === Qt.LeftButton || mouse.button === Qt.MiddleButton) {
                        if (taskItem.dockRoot && typeof taskItem.dockRoot.closeAllContextMenus === "function") {
                            taskItem.dockRoot.closeAllContextMenus();
                        }
                    }
                    if (mouse.button === Qt.LeftButton) {
                        if (taskItem.isLauncher && !taskItem.isWindow) {
                            if (taskItem.dockRoot && taskItem.dockRoot.requestHideWindowPreviewImmediately) {
                                taskItem.dockRoot.requestHideWindowPreviewImmediately();
                            }
                            taskItem.tasksModel.requestActivate(idx);
                        } else if (taskItem.isWindow) {
                            var isGroup = model ? Boolean(model.IsGroupParent) : false;
                            var childCount = model ? (model.ChildCount || 0) : 0;
                            if (isGroup && childCount > 1) {
                                if (taskItem.dockRoot && taskItem.dockRoot.requestToggleWindowPreview) {
                                    taskItem.dockRoot.requestToggleWindowPreview(buttonContainer, taskItem.index, taskItem.childCount, taskItem.appName, taskItem.model ? (taskItem.model.decoration || taskItem.model.icon) : null, taskItem.model ? taskItem.model.WinIdList : []);
                                }
                            } else {
                                if (taskItem.dockRoot && taskItem.dockRoot.requestHideWindowPreviewImmediately) {
                                    taskItem.dockRoot.requestHideWindowPreviewImmediately();
                                }
                                if (taskItem.isActive) {
                                    taskItem.triggerMinimizeBounce();
                                    taskItem.tasksModel.requestToggleMinimized(idx);
                                } else {
                                    taskItem.tasksModel.requestActivate(idx);
                                }
                            }
                        }
                    } else if (mouse.button === Qt.MiddleButton) {
                        if (taskItem.isWindow) {
                            taskItem.tasksModel.requestNewInstance(idx);
                        }
                    } else if (mouse.button === Qt.RightButton) {
                        contextMenu.open();
                    }
                }
            }
        }
    }

    SequentialAnimation {
        id: minimizeBounceAnimation

        // 1. Icon dips down touching the indicator line
        NumberAnimation {
            target: taskItem
            property: "iconYOffset"
            from: 0
            to: 3.5
            duration: 80
            easing.type: Easing.OutQuad
        }

        // 2. Icon bounces back up while indicator squishes slightly and settles
        ParallelAnimation {
            NumberAnimation {
                target: taskItem
                property: "iconYOffset"
                from: 3.5
                to: 0
                duration: 140
                easing.type: Easing.OutBack
                easing.overshoot: 1.1
            }
            SequentialAnimation {
                NumberAnimation {
                    target: statusIndicator
                    property: "extraWidth"
                    from: 0
                    to: 3.5
                    duration: 50
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: statusIndicator
                    property: "extraWidth"
                    to: 0
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    TaskContextMenu {
        id: contextMenu
        visualParent: buttonContainer
        tasksModel: taskItem.tasksModel
        dockRoot: taskItem.dockRoot
        modelIndex: taskItem.getModelIndex()
        isWindow: taskItem.isWindow
        isLauncher: taskItem.isLauncher
        hasLauncher: taskItem.hasLauncher
        launcherUrl: taskItem.launcherUrl
        appId: taskItem.appId

        onStatusChanged: {
            if (contextMenu.status) {
                if (taskItem.dockRoot && taskItem.dockRoot.requestHideTooltip) {
                    taskItem.dockRoot.requestHideTooltip(buttonContainer);
                }
                if (taskItem.dockRoot && taskItem.dockRoot.requestHideWindowPreviewImmediately) {
                    taskItem.dockRoot.requestHideWindowPreviewImmediately();
                }
            }
        }
    }

    Component.onDestruction: {
        if (taskItem.dockRoot && taskItem.dockRoot.requestHideTooltip) {
            taskItem.dockRoot.requestHideTooltip(buttonContainer);
        }
        if (taskItem.dockRoot && taskItem.dockRoot.requestHideWindowPreviewImmediately) {
            taskItem.dockRoot.requestHideWindowPreviewImmediately();
        }
    }
}

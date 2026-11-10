/*
 * SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-FileCopyrightText: 2022 Friedrich Schriewer <friedrich.schriewer@gmx.net>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

GridView {
    id: grid

    property bool movedWithKeyboard: false
    property bool movedWithWheel: false

    property bool showScrollBar: true
    readonly property int columns: (typeof root !== "undefined" && root.plasmoidConfiguration && root.plasmoidConfiguration.numberColumns) ? root.plasmoidConfiguration.numberColumns : 6

    focus: true
    clip: true
    currentIndex: count > 0 ? 0 : -1
    interactive: height < contentHeight
    reuseItems: true
    boundsBehavior: Flickable.StopAtBounds
    // default keyboard navigation doesn't allow focus reasons to be used
    // and eats up/down key events when at the beginning or end of the list.
    keyNavigationEnabled: false
    keyNavigationWraps: false

    highlightMoveDuration: 0

    cellWidth: root.cellSizeWidth
    cellHeight: root.cellSizeHeight

    highlight: null

    delegate: FavoriteItem {
        id: favitem
        triggerModel: grid.model
    }

    move: null
    moveDisplaced: null

    Item {
        id: scrollBarContainer
        parent: root.launcherContainer
        z: 99

        anchors.right: parent ? parent.right : undefined
        anchors.rightMargin: 5

        y: root.containerInnerPadding + (typeof main !== "undefined" && main ? main.searchBar.height + main.itemSpacing : 53)
        height: grid.height
        width: 14

        visible: grid.visible && grid.showScrollBar && (grid.contentHeight > grid.height)

        Rectangle {
            id: scrollTrack
            anchors.fill: parent
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => {
                    var maxScroll = grid.contentHeight - grid.height;
                    if (maxScroll <= 0) return;
                    var clickRatio = mouse.y / parent.height;
                    grid.contentY = grid.originY + (clickRatio * maxScroll);
                }
            }
        }

        Rectangle {
            id: scrollThumb

            readonly property real maxTravel: Math.max(0, scrollBarContainer.height - height)
            readonly property real maxScroll: Math.max(1, grid.contentHeight - grid.height)
            readonly property real scrollRatio: Math.max(0, Math.min(1.0, (grid.contentY - grid.originY) / maxScroll))

            anchors.right: parent.right
            anchors.rightMargin: 1
            width: thumbMouseArea.containsMouse || thumbMouseArea.drag.active ? 6 : 4
            height: Math.round(root.cellSizeHeight * 0.60)
            radius: width / 2

            y: Math.max(0, Math.min(maxTravel, scrollRatio * maxTravel))

            color: thumbMouseArea.containsMouse || thumbMouseArea.drag.active
                ? Kirigami.Theme.highlightColor
                : Qt.rgba(main.textColor.r, main.textColor.g, main.textColor.b, 0.35)

            Behavior on width {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            MouseArea {
                id: thumbMouseArea
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                property real startY: 0
                property real startContentY: 0

                onPressed: mouse => {
                    startY = mouse.y;
                    startContentY = grid.contentY;
                }

                onPositionChanged: mouse => {
                    if (pressed && scrollThumb.maxTravel > 0) {
                        var deltaY = mouse.y - startY;
                        var deltaScroll = (deltaY / scrollThumb.maxTravel) * scrollThumb.maxScroll;
                        grid.contentY = Math.max(grid.originY, Math.min(grid.originY + scrollThumb.maxScroll, startContentY + deltaScroll));
                    }
                }
            }
        }
    }

    Kirigami.WheelHandler {
        id: wheelHandler
        target: grid
        filterMouseEvents: true
        // `20 * Qt.styleHints.wheelScrollLines` is the default speed.
        horizontalStepSize: 20 * Qt.styleHints.wheelScrollLines
        verticalStepSize: 20 * Qt.styleHints.wheelScrollLines

        onWheel: wheel => {
            grid.movedWithWheel = true
            grid.movedWithKeyboard = false
            movedWithWheelTimer.restart()
        }
    }

    Connections {
        target: root
        function onVisibleChanged() {
            if (!root.visible) {
                grid.currentIndex = 0
                grid.positionViewAtBeginning()
            }
        }
    }

    // Used to block hover events temporarily after using keyboard navigation.
    // If you have one hand on the touch pad or mouse and another hand on the keyboard,
    // it's easy to accidentally reset the highlight/focus position to the mouse position.
    Timer {
        id: movedWithKeyboardTimer
        interval: 200
        onTriggered: grid.movedWithKeyboard = false
    }

    Timer {
        id: movedWithWheelTimer
        interval: 200
        onTriggered: grid.movedWithWheel = false
    }

    function focusCurrentItem(event, focusReason) {
        currentItem.forceActiveFocus(focusReason)
        event.accepted = true
    }

    Keys.onPressed: event => {
        const targetX = currentItem ? currentItem.x : contentX
        let targetY = currentItem ? currentItem.y : contentY
        let targetIndex = currentIndex
        // supports mirroring
        const atLeft = currentIndex % columns === (Qt.application.layoutDirection == Qt.RightToLeft ? columns - 1 : 0)
        // at the beginning of a line
        const isLeading = currentIndex % columns === 0
        // at the top of a given column and in the top row
        const atTop = currentIndex < columns
        // supports mirroring
        const atRight = currentIndex % columns === (Qt.application.layoutDirection == Qt.RightToLeft ? 0 : columns - 1)
        // at the end of a line
        const isTrailing = currentIndex % columns === columns - 1
        // at bottom of a given column, not necessarily in the last row
        let atBottom = currentIndex >= count - columns
        // Implements the keyboard navigation described in https://www.w3.org/TR/wai-aria-practices-1.2/#grid
        if (count > 1) {
            switch (event.key) {
                case Qt.Key_Left: if (!atLeft && !searchBar.textField.activeFocus) {
                    moveCurrentIndexLeft()
                    focusCurrentItem(event, Qt.BacktabFocusReason)
                } break
                case Qt.Key_H: if (!atLeft && !searchBar.textField.activeFocus && event.modifiers & Qt.ControlModifier) {
                    moveCurrentIndexLeft()
                    focusCurrentItem(event, Qt.BacktabFocusReason)
                } break
                case Qt.Key_Up: if (!atTop) {
                    moveCurrentIndexUp()
                    focusCurrentItem(event, Qt.BacktabFocusReason)
                } else {
                    searchBar.textField.forceActiveFocus(Qt.BacktabFocusReason);
                    event.accepted = true;
                } break
                case Qt.Key_K: if (!atTop && event.modifiers & Qt.ControlModifier) {
                    moveCurrentIndexUp()
                    focusCurrentItem(event, Qt.BacktabFocusReason)
                } break
                case Qt.Key_Right: if (!atRight && !searchBar.textField.activeFocus) {
                    moveCurrentIndexRight()
                    focusCurrentItem(event, Qt.TabFocusReason)
                } break
                case Qt.Key_L: if (!atRight && !searchBar.textField.activeFocus && event.modifiers & Qt.ControlModifier) {
                    moveCurrentIndexRight()
                    focusCurrentItem(event, Qt.TabFocusReason)
                } break
                case Qt.Key_Down: if (!atBottom) {
                    moveCurrentIndexDown()
                    focusCurrentItem(event, Qt.TabFocusReason)
                } break
                case Qt.Key_J: if (!atBottom && event.modifiers & Qt.ControlModifier) {
                    moveCurrentIndexDown()
                    focusCurrentItem(event, Qt.TabFocusReason)
                } break
                case Qt.Key_Home: if (event.modifiers === Qt.ControlModifier && currentIndex !== 0) {
                    currentIndex = 0
                    focusCurrentItem(event, Qt.BacktabFocusReason)
                } else if (!isLeading) {
                    targetIndex -= currentIndex % columns
                    currentIndex = Math.max(targetIndex, 0)
                    focusCurrentItem(event, Qt.BacktabFocusReason)
                } break
                case Qt.Key_End: if (event.modifiers === Qt.ControlModifier && currentIndex !== count - 1) {
                    currentIndex = count - 1
                    focusCurrentItem(event, Qt.TabFocusReason)
                } else if (!isTrailing) {
                    targetIndex += columns - 1 - (currentIndex % columns)
                    currentIndex = Math.min(targetIndex, count - 1)
                    focusCurrentItem(event, Qt.TabFocusReason)
                } break
                case Qt.Key_PageUp: if (!atTop) {
                    targetY = targetY - height + 1
                    targetIndex = indexAt(targetX, targetY)
                    while (targetIndex === -1) {
                        targetY += 1
                        targetIndex = indexAt(targetX, targetY)
                    }
                    currentIndex = Math.max(targetIndex, 0)
                    focusCurrentItem(event, Qt.BacktabFocusReason)
                } break
                case Qt.Key_PageDown: if (!atBottom) {
                    targetY = targetY + height - 1
                    targetIndex = indexAt(targetX, targetY)
                    while (targetIndex === -1) {
                        targetY -= 1
                        targetIndex = indexAt(targetX, targetY)
                    }
                    currentIndex = Math.min(targetIndex, count - 1)
                    focusCurrentItem(event, Qt.TabFocusReason)
                } break
                case Qt.Key_Return:
                    /* Fall through*/
                case Qt.Key_Enter:
                    grid.currentItem.trigger();
                    grid.currentItem.forceActiveFocus(Qt.ShortcutFocusReason);
                    event.accepted = true;
                    break;
            }
        }

        if (!event.accepted && event.key !== Qt.Key_Escape && event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter) {
            if (event.key === Qt.Key_Backspace) {
                searchBar.textField.forceActiveFocus();
                if (searchBar.textField.text.length > 0) {
                    searchBar.textField.text = searchBar.textField.text.slice(0, -1);
                }
                event.accepted = true;
            } else if (event.text && event.text.length > 0 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                searchBar.textField.forceActiveFocus();
                searchBar.textField.text += event.text;
                event.accepted = true;
            }
        }

        movedWithKeyboard = event.accepted
        if (movedWithKeyboard) {
            movedWithKeyboardTimer.restart()
        }
    }
}
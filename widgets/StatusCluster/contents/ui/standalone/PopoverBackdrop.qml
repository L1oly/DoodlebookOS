/*
    SPDX-FileCopyrightText: 2026 DoodlebookOS
    SPDX-License-Identifier: GPL-3.0-or-later

    Invisible layer-surface shown underneath the standalone popovers. It covers
    the work area (below the bar) so "click anywhere outside the drawer to close
    it" works on compositors (such as niri) that do not move keyboard focus to
    layer-shell popovers.

    Keyboard interactivity is intentionally OnDemand: with `None`, niri sends
    the first outside click to the window underneath (just focusing it) and the
    backdrop only sees the second click, which feels like needing a double click.
*/

import QtQuick
import QtQuick.Window
import org.kde.layershell as LayerShell

Window {
    id: backdrop
    objectName: "doodlebookPopoverBackdrop"
    title: "DoodlebookOS Popover Backdrop"

    readonly property bool wantsVisible: typeof PopoverState !== "undefined" && PopoverState
        ? (PopoverState.quicksettingsVisible || PopoverState.notificationsVisible)
        : false

    visible: wantsVisible
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    width: screen ? screen.width : 1920
    height: screen ? screen.height : 1080

    LayerShell.Window.scope: "doodlebook-popover-backdrop"
    LayerShell.Window.anchors: LayerShell.Window.AnchorTop
                             | LayerShell.Window.AnchorBottom
                             | LayerShell.Window.AnchorLeft
                             | LayerShell.Window.AnchorRight
    LayerShell.Window.layer: LayerShell.Window.LayerTop
    LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityOnDemand

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: {
            if (typeof PopoverState !== "undefined" && PopoverState) {
                PopoverState.hideAll();
            }
        }
    }
}

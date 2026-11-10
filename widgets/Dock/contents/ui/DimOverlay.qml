/*
 * SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.kde.layershell as LayerShell

Window {
    id: overlayRoot

    property real bottomGap: 52
    property real targetOpacity: 0.175

    flags: Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus
    color: "transparent"

    LayerShell.Window.scope: "dim-overlay"
    LayerShell.Window.layer: LayerShell.Window.LayerTop
    LayerShell.Window.anchors: LayerShell.Window.AnchorTop | LayerShell.Window.AnchorBottom | LayerShell.Window.AnchorLeft | LayerShell.Window.AnchorRight
    LayerShell.Window.exclusionZone: -1
    LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityNone
    LayerShell.Window.margins.top: 0
    LayerShell.Window.margins.bottom: overlayRoot.bottomGap
    LayerShell.Window.margins.left: 0
    LayerShell.Window.margins.right: 0

    property real dimOpacity: 0.0

    function showOverlay() {
        if (hideTimer.running) hideTimer.stop();
        overlayRoot.visible = true;
        overlayRoot.dimOpacity = overlayRoot.targetOpacity;
    }

    function hideOverlay() {
        overlayRoot.dimOpacity = 0.0;
        hideTimer.restart();
    }

    Rectangle {
        id: dimRect
        anchors.fill: parent
        color: "#000000"
        opacity: overlayRoot.dimOpacity

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (typeof kicker !== "undefined" && kicker.launcherPopup) {
                    kicker.launcherPopup.close();
                }
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 160
        repeat: false
        onTriggered: {
            overlayRoot.visible = false;
        }
    }
}

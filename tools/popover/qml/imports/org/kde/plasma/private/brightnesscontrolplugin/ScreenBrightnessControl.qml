/*
    SPDX-FileCopyrightText: 2026 DoodlebookOS
    SPDX-License-Identifier: GPL-3.0-or-later

    Minimal replacement for PowerDevil's ScreenBrightnessControl used by the
    standalone popover. The daemon handles DDC/CI (desktop monitors), kernel
    backlights (laptops) and a gamma-control fallback.
*/

import QtQuick

Item {
    id: control

    readonly property bool isBrightnessAvailable: (typeof Backend !== "undefined" && Backend)
        ? Backend.brightnessAvailable : false

    readonly property var displays: displayModel

    function syncFromBackend() {
        if (typeof Backend !== "undefined" && Backend && displayModel.count > 0) {
            displayModel.setProperty(0, "brightness", Backend.brightness);
        }
    }

    function setBrightness(displayName, value) {
        if (typeof Backend !== "undefined" && Backend) {
            Backend.setBrightness(value);
        }
    }

    ListModel {
        id: displayModel
        ListElement {
            displayName: "default"
            brightness: 100
            maxBrightness: 100
        }
    }

    Connections {
        target: (typeof Backend !== "undefined") ? Backend : null
        function onBrightnessChanged() {
            control.syncFromBackend();
        }
    }

    Component.onCompleted: syncFromBackend()
}

/*
    SPDX-FileCopyrightText: 2026 DoodlebookOS
    SPDX-License-Identifier: GPL-3.0-or-later

    Minimal org.kde.plasma.plasma5support.DataSource stub used by the standalone
    DoodlebookOS popover. It forwards commands to the Python `Backend` context
    property instead of requiring the full plasma-workspace runtime.
*/

import QtQuick

QtObject {
    id: dataSource

    property string engine: "executable"
    property var connectedSources: []

    signal newData(string sourceName, var data)

    function connectSource(sourceName) {
        if (typeof Backend !== "undefined" && Backend) {
            Backend.exec(sourceName);
        }
        // Emit synchronously; the executable engine in Plasma only calls back
        // with the output, which the callers simply discard.
        dataSource.newData(sourceName, "");
    }

    function disconnectSource(sourceName) {
    }
}

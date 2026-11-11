import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import "i18n.js" as I18n

Item {
    id: editRoot

    function i18n(k, a1, a2) { return I18n.t(k, a1, a2); }

    property var fullRep: null
    property int selectedTileIndex: -1

    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1.0
    function snap(val) {
        return Math.round(val * dpr) / dpr;
    }

    readonly property string appFontFamily: "Google Sans Flex"

    implicitHeight: editHeader.height + editScroll.anchors.topMargin + editCol.implicitHeight + snap(16.0)

    signal closeRequested()

    function deleteSelected() {
        if (!fullRep || !fullRep.activeTiles || fullRep.activeTiles.length === 0) return;
        var arr = fullRep.activeTiles.slice();
        if (selectedTileIndex >= 0 && selectedTileIndex < arr.length) {
            arr.splice(selectedTileIndex, 1);
        } else {
            arr.pop();
        }
        fullRep.activeTiles = arr;
        selectedTileIndex = -1;
        fullRep.saveActiveTiles();
    }

    function addTile(tileId) {
        if (!fullRep || !fullRep.activeTiles) return;
        if (fullRep.activeTiles.indexOf(tileId) !== -1) return;
        var arr = fullRep.activeTiles.slice();
        arr.push(tileId);
        fullRep.activeTiles = arr;
        if (fullRep.setTileSpan) {
            fullRep.setTileSpan(tileId, 2);
        }
        selectedTileIndex = arr.length - 1;
        fullRep.saveActiveTiles();
    }

    function resetTiles() {
        if (!fullRep || !fullRep.defaultTiles) return;
        fullRep.activeTiles = fullRep.defaultTiles.slice();
        fullRep.tileSpans = {};
        selectedTileIndex = -1;
        fullRep.saveActiveTiles();
    }

    function moveTile(fromIndex, toIndex) {
        if (!fullRep || !fullRep.activeTiles) return;
        if (fromIndex === toIndex) return;
        if (fromIndex < 0 || fromIndex >= fullRep.activeTiles.length) return;
        if (toIndex < 0 || toIndex >= fullRep.activeTiles.length) return;

        var arr = fullRep.activeTiles.slice();
        var item = arr.splice(fromIndex, 1)[0];
        arr.splice(toIndex, 0, item);
        fullRep.activeTiles = arr;
        selectedTileIndex = toIndex;
        fullRep.saveActiveTiles();
    }

    readonly property var categories: [
        {
            id: "lacznosc",
            title: i18n("Connectivity"),
            icon: Qt.resolvedUrl("icons/wifi.svg"),
            tiles: [
                { id: "wifi", name: i18n("Wi-Fi"), icon: Qt.resolvedUrl("icons/wifi.svg") },
                { id: "bluetooth", name: i18n("Bluetooth"), icon: Qt.resolvedUrl("icons/bluetooth.svg") },
                { id: "quickshare", name: i18n("Quick\\nShare"), icon: Qt.resolvedUrl("icons/quickshare.svg") },
                { id: "localshare", name: i18n("Local\\nShare"), icon: Qt.resolvedUrl("icons/localshare.svg") },
                { id: "tailscale", name: i18n("Tail\\nscale"), icon: Qt.resolvedUrl("icons/tailscale.svg") }
            ]
        },
        {
            id: "system",
            title: i18n("System & power"),
            icon: Qt.resolvedUrl("icons/laptop_screen.svg"),
            tiles: [
                { id: "battery_saver", name: i18n("Power &\\nbattery"), icon: Qt.resolvedUrl("icons/battery_saver.svg") },
                { id: "powerprofiles", name: i18n("Power\\nprofile"), icon: Qt.resolvedUrl("icons/power_profiles.svg") },
                { id: "caffeine", name: i18n("Caffeine"), icon: Qt.resolvedUrl("icons/caffeine.svg") },
                { id: "dark_mode", name: i18n("Dark\\ntheme"), icon: Qt.resolvedUrl("icons/dark_mode.svg") },
                { id: "modes", name: i18n("Do not\\ndisturb"), icon: Qt.resolvedUrl("icons/modes.svg") }
            ]
        },
        {
            id: "narzedzia",
            title: i18n("Tools"),
            icon: Qt.resolvedUrl("icons/settings.svg"),
            tiles: [
                { id: "screenshot", name: i18n("Screenshot"), icon: Qt.resolvedUrl("icons/screenshot.svg") },
                { id: "mic", name: i18n("Microphone\\naccess"), icon: Qt.resolvedUrl("icons/mic.svg") },
                { id: "keyboard", name: i18n("Keyboard"), icon: Qt.resolvedUrl("icons/keyboard.svg") }
            ]
        }
    ]

    // Sticky Top Header
    Rectangle {
        id: editHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: snap(32.0)
        color: "transparent"
        z: 10

        // Back Arrow Button (Left)
        Rectangle {
            id: backBtn
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: snap(32.0)
            height: snap(32.0)
            radius: snap(8.0)
            color: backMouse.pressed
                   ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
                   : (backMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1) : "transparent")

            Kirigami.Icon {
                anchors.centerIn: parent
                width: snap(24.0)
                height: snap(24.0)
                source: Qt.resolvedUrl("icons/arrow_back.svg")
                isMask: true
                color: Kirigami.Theme.textColor
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    editRoot.closeRequested();
                }
            }
        }

        // Centered Title
        PlasmaComponents3.Label {
            anchors.centerIn: parent
            text: i18n("Edit tiles")
            font.family: editRoot.appFontFamily
            font.pixelSize: snap(13.6)
            font.weight: Font.DemiBold
            color: Kirigami.Theme.textColor
        }

        // Remove Pill Button (Right)
        Rectangle {
            id: delBtn
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: snap(68.0)
            height: snap(30.4)
            radius: height / 2
            color: fullRep ? fullRep.effectiveAccentColor : Kirigami.Theme.linkColor

            readonly property bool canDelete: editRoot.selectedTileIndex >= 0 || (fullRep && fullRep.activeTiles && fullRep.activeTiles.length > 0)
            opacity: canDelete
                     ? (delMouse.pressed ? 0.75 : (delMouse.containsMouse ? 0.90 : 1.0))
                     : 0.4

            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }

            PlasmaComponents3.Label {
                anchors.centerIn: parent
                text: i18n("Remove")
                font.family: editRoot.appFontFamily
                font.pixelSize: snap(10.4)
                font.weight: Font.DemiBold
                color: fullRep ? ((fullRep.effectiveAccentColor.r * 0.299 + fullRep.effectiveAccentColor.g * 0.587 + fullRep.effectiveAccentColor.b * 0.114) > 0.6 ? "#111827" : Kirigami.Theme.highlightedTextColor) : "#111827"
            }

            MouseArea {
                id: delMouse
                anchors.fill: parent
                enabled: delBtn.canDelete
                hoverEnabled: true
                onClicked: {
                    editRoot.deleteSelected();
                }
            }
        }
    }

    // Scrollable content underneath the sticky header
    Flickable {
        id: editScroll
        anchors.top: editHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: snap(9.6)
        anchors.bottomMargin: 0
        contentWidth: width
        contentHeight: editCol.implicitHeight + snap(16.0)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        PlasmaComponents3.ScrollBar.vertical: PlasmaComponents3.ScrollBar {
            id: vbar
        }

        WheelHandler {
            target: editScroll
        }

        ColumnLayout {
            id: editCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            spacing: snap(14.4)

            // 1. Top Card: Outlined Container of Active Tiles
            Rectangle {
                id: activeTilesContainer
                Layout.fillWidth: true
                radius: snap(16.0)
                color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.45)
                border.width: snap(1.2)
                border.color: fullRep ? Qt.rgba(fullRep.effectiveAccentColor.r, fullRep.effectiveAccentColor.g, fullRep.effectiveAccentColor.b, 0.4) : "#334e8f"
                implicitHeight: activeGrid.implicitHeight + snap(16.0)

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: {
                        editRoot.selectedTileIndex = -1;
                    }
                }

                GridLayout {
                    id: activeGrid
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: snap(8.0)
                    columns: 4
                    rowSpacing: snap(7.2)
                    columnSpacing: snap(7.2)

                    Repeater {
                        model: fullRep ? fullRep.activeTiles : []

                        Rectangle {
                            id: tileItem
                            required property string modelData
                            required property int index

                            readonly property int span: fullRep ? fullRep.getTileSpan(modelData) : 2
                            readonly property bool isCompact: span === 1

                            Layout.columnSpan: span
                            Layout.fillWidth: true
                            Layout.preferredWidth: isCompact ? snap(68.0) : snap(143.2)
                            Layout.preferredHeight: snap(49.6)
                            radius: snap(14.4)
                            color: fullRep ? fullRep.oneUiTrackBg : "#23252d"

                            readonly property bool isSelected: editRoot.selectedTileIndex === index
                            border.width: isSelected ? snap(1.6) : 0
                            border.color: fullRep ? fullRep.effectiveAccentColor : Kirigami.Theme.linkColor

                            // Handle on right edge of selected tile for resizing (1 segment <-> 2 segments)
                            Rectangle {
                                id: selHandle
                                visible: tileItem.isSelected
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: snap(2.4)
                                width: snap(16.0)
                                height: snap(28.8)
                                radius: snap(6.0)
                                color: fullRep ? fullRep.effectiveAccentColor : Kirigami.Theme.linkColor
                                z: 10

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: snap(12.0)
                                    height: snap(12.0)
                                    source: Qt.resolvedUrl("icons/arrow_right.svg")
                                    rotation: tileItem.isCompact ? 0 : 180
                                    isMask: true
                                    color: (fullRep && (fullRep.effectiveAccentColor.r * 0.299 + fullRep.effectiveAccentColor.g * 0.587 + fullRep.effectiveAccentColor.b * 0.114) > 0.6) ? "#111827" : Kirigami.Theme.highlightedTextColor
                                }

                                MouseArea {
                                    id: handleMouse
                                    anchors.fill: parent
                                    anchors.margins: -snap(6.4)
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    property real startX: 0
                                    property bool dragged: false

                                    onPressed: (mouse) => {
                                        startX = mouse.x;
                                        dragged = false;
                                    }

                                    onPositionChanged: (mouse) => {
                                        if (pressed) {
                                            var dx = mouse.x - startX;
                                            if (Math.abs(dx) > 12) {
                                                dragged = true;
                                                if (dx < -12 && tileItem.span === 2) {
                                                    fullRep.setTileSpan(tileItem.modelData, 1);
                                                } else if (dx > 12 && tileItem.span === 1) {
                                                    fullRep.setTileSpan(tileItem.modelData, 2);
                                                }
                                            }
                                        }
                                    }

                                    onClicked: {
                                        if (!dragged) {
                                            var nextSpan = tileItem.span === 2 ? 1 : 2;
                                            fullRep.setTileSpan(tileItem.modelData, nextSpan);
                                        }
                                        dragged = false;
                                    }
                                }
                            }

                            // 1-span Compact layout: centered icon
                            Kirigami.Icon {
                                visible: tileItem.isCompact
                                anchors.centerIn: parent
                                width: snap(20.8)
                                height: width
                                source: fullRep ? fullRep.getTileIcon(tileItem.modelData) : ""
                                isMask: true
                                color: Kirigami.Theme.textColor
                            }

                            // 2-span Wide layout: icon badge + title (no secondary text)
                            RowLayout {
                                visible: !tileItem.isCompact
                                anchors.fill: parent
                                anchors.leftMargin: snap(8.0)
                                anchors.rightMargin: snap(8.0)
                                spacing: snap(8.0)

                                Rectangle {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredWidth: snap(28.8)
                                    Layout.preferredHeight: snap(28.8)
                                    radius: snap(14.4)
                                    color: "transparent"

                                    Kirigami.Icon {
                                        anchors.centerIn: parent
                                        width: snap(19.2)
                                        height: width
                                        source: fullRep ? fullRep.getTileIcon(tileItem.modelData) : ""
                                        isMask: true
                                        color: Kirigami.Theme.textColor
                                    }
                                }

                                PlasmaComponents3.Label {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    text: fullRep ? fullRep.getTileTitle(tileItem.modelData) : tileItem.modelData
                                    font.family: editRoot.appFontFamily
                                    font.pixelSize: snap(11.2)
                                    font.weight: Font.DemiBold
                                    color: Kirigami.Theme.textColor
                                    elide: Text.ElideRight
                                }
                            }

                            // Selection / Press overlay
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: Kirigami.Theme.textColor
                                opacity: tileMouse.pressed ? 0.18 : (tileMouse.containsMouse ? 0.08 : 0)
                            }

                            MouseArea {
                                id: tileMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: false
                                property real startX: 0
                                property real startY: 0
                                property bool isDragging: false

                                onPressed: (mouse) => {
                                    startX = mouse.x;
                                    startY = mouse.y;
                                    isDragging = false;
                                }

                                onPositionChanged: (mouse) => {
                                    if (pressed && !isDragging) {
                                        var dx = Math.abs(mouse.x - startX);
                                        var dy = Math.abs(mouse.y - startY);
                                        if (dx > 15 || dy > 15) {
                                            isDragging = true;
                                        }
                                    }
                                    if (isDragging) {
                                        var mapped = mapToItem(activeGrid, mouse.x, mouse.y);
                                        var colW = activeGrid.width / 4;
                                        var rowH = snap(49.6) + activeGrid.rowSpacing;
                                        var col = Math.min(3, Math.max(0, Math.floor(mapped.x / colW)));
                                        var row = Math.max(0, Math.floor(mapped.y / rowH));
                                        var targetIdx = Math.min(fullRep.activeTiles.length - 1, Math.max(0, row * 2 + Math.floor(col / 2)));
                                        if (targetIdx !== tileItem.index) {
                                            editRoot.moveTile(tileItem.index, targetIdx);
                                        }
                                    }
                                }

                                onClicked: {
                                    if (!isDragging) {
                                        if (editRoot.selectedTileIndex === tileItem.index) {
                                            editRoot.selectedTileIndex = -1;
                                        } else {
                                            editRoot.selectedTileIndex = tileItem.index;
                                        }
                                    }
                                    isDragging = false;
                                }
                            }
                        }
                    }
                }
            }

            // 2. Categories of Available Tiles
            Repeater {
                model: editRoot.categories

                ColumnLayout {
                    id: catCol
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: snap(9.6)

                    // Category Title Row
                    RowLayout {
                        spacing: snap(6.4)
                        Layout.fillWidth: true

                        Kirigami.Icon {
                            Layout.preferredWidth: snap(16.0)
                            Layout.preferredHeight: snap(16.0)
                            source: catCol.modelData.icon
                            isMask: true
                            color: Kirigami.Theme.textColor
                        }

                        PlasmaComponents3.Label {
                            text: catCol.modelData.title
                            font.family: editRoot.appFontFamily
                            font.pixelSize: snap(12.0)
                            font.weight: Font.DemiBold
                            color: Kirigami.Theme.textColor
                        }
                    }

                    // 4-Column Grid of Available Circular Tiles
                    GridLayout {
                        columns: 4
                        Layout.fillWidth: true
                        rowSpacing: snap(11.2)
                        columnSpacing: snap(4.8)

                        Repeater {
                            model: catCol.modelData.tiles

                            Item {
                                id: availTileItem
                                required property var modelData

                                Layout.fillWidth: true
                                implicitHeight: snap(70.4)

                                readonly property bool isAdded: fullRep && fullRep.activeTiles ? (fullRep.activeTiles.indexOf(availTileItem.modelData.id) !== -1) : false

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    width: parent.width
                                    spacing: snap(4.8)

                                    // Circular Button Container
                                    Item {
                                        Layout.alignment: Qt.AlignHCenter
                                        width: snap(44.8)
                                        height: snap(44.8)

                                        Rectangle {
                                            id: circBase
                                            anchors.fill: parent
                                            radius: width / 2
                                            color: fullRep ? fullRep.oneUiTrackBg : "#1e265c"
                                            opacity: availTileItem.isAdded ? 0.35 : 1.0
                                            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }

                                            Kirigami.Icon {
                                                anchors.centerIn: parent
                                                width: snap(20.8)
                                                height: snap(20.8)
                                                source: availTileItem.modelData.icon
                                                isMask: true
                                                color: Kirigami.Theme.textColor
                                            }

                                            // Press / hover feedback on circle
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: parent.radius
                                                color: Kirigami.Theme.textColor
                                                opacity: (!availTileItem.isAdded && circArea.pressed) ? 0.22 : ((!availTileItem.isAdded && circArea.containsMouse) ? 0.10 : 0)
                                            }
                                        }

                                        // Plus Badge at Top-Right
                                        Rectangle {
                                            id: plusBadge
                                            visible: !availTileItem.isAdded
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.topMargin: -snap(1.6)
                                            anchors.rightMargin: -snap(1.6)
                                            width: snap(16.0)
                                            height: snap(16.0)
                                            radius: width / 2
                                            color: fullRep ? fullRep.effectiveAccentColor : Kirigami.Theme.linkColor
                                            z: 2

                                            PlasmaComponents3.Label {
                                                anchors.centerIn: parent
                                                text: "+"
                                                font.family: editRoot.appFontFamily
                                                font.pixelSize: snap(12.0)
                                                font.bold: true
                                                color: fullRep ? ((fullRep.effectiveAccentColor.r * 0.299 + fullRep.effectiveAccentColor.g * 0.587 + fullRep.effectiveAccentColor.b * 0.114) > 0.6 ? "#111827" : Kirigami.Theme.highlightedTextColor) : "#111827"
                                            }
                                        }

                                        MouseArea {
                                            id: circArea
                                            anchors.fill: parent
                                            hoverEnabled: !availTileItem.isAdded
                                            preventStealing: false
                                            onClicked: {
                                                if (!availTileItem.isAdded) {
                                                    editRoot.addTile(availTileItem.modelData.id);
                                                }
                                            }
                                        }
                                    }

                                    // Label below circle
                                    PlasmaComponents3.Label {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: availTileItem.modelData.name
                                        font.family: editRoot.appFontFamily
                                        font.pixelSize: snap(8.8)
                                        color: Kirigami.Theme.textColor
                                        opacity: availTileItem.isAdded ? 0.35 : 1.0
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        lineHeight: 0.95
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 3. Reset Button at the Bottom
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: snap(40.0)
                Layout.topMargin: snap(8.0)
                Layout.bottomMargin: snap(19.2)

                Rectangle {
                    anchors.centerIn: parent
                    implicitWidth: snap(88.0)
                    implicitHeight: snap(30.4)
                    radius: height / 2
                    color: fullRep ? fullRep.effectiveAccentColor : Kirigami.Theme.linkColor
                    opacity: resetArea.pressed ? 0.75 : (resetArea.containsMouse ? 0.90 : 1.0)
                    Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }

                    PlasmaComponents3.Label {
                        anchors.centerIn: parent
                        text: i18n("Reset")
                        font.family: editRoot.appFontFamily
                        font.pixelSize: snap(10.4)
                        font.weight: Font.DemiBold
                        color: fullRep ? ((fullRep.effectiveAccentColor.r * 0.299 + fullRep.effectiveAccentColor.g * 0.587 + fullRep.effectiveAccentColor.b * 0.114) > 0.6 ? "#111827" : Kirigami.Theme.highlightedTextColor) : "#111827"
                    }

                    MouseArea {
                        id: resetArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            editRoot.resetTiles();
                        }
                    }
                }
            }
        }
    }
}

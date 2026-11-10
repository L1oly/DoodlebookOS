import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.bluezqt as BluezQt
import org.kde.kcmutils as KCMUtils
import "i18n.js" as I18n

Item {
    id: bluetoothViewRoot

    function i18n(k, a1, a2) { return I18n.t(k, a1, a2); }

    property var fullRep: null

    readonly property string appFontFamily: "Google Sans Flex"

    property bool isExpanded: false

    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1.0
    function snap(val) {
        return Math.round(val * dpr) / dpr;
    }

    signal closeRequested()

    readonly property bool isDiscovering: Boolean(BluezQt.Manager && BluezQt.Manager.usableAdapter && BluezQt.Manager.usableAdapter.discovering)
    property int _updateTrigger: 0

    Connections {
        target: (typeof BluezQt !== "undefined" && BluezQt.Manager) ? BluezQt.Manager : null
        function onDeviceAdded() { bluetoothViewRoot._updateTrigger++; }
        function onDeviceRemoved() { bluetoothViewRoot._updateTrigger++; }
        function onDeviceChanged() { bluetoothViewRoot._updateTrigger++; }
        function onUsableAdapterChanged() { bluetoothViewRoot._updateTrigger++; }
        function onBluetoothOperationalChanged() { bluetoothViewRoot._updateTrigger++; }
    }

    // Helper functions for filtering devices
    function getConnectedDevices() {
        var dummy = _updateTrigger;
        if (!BluezQt.Manager || !BluezQt.Manager.devices) return [];
        var res = [];
        for (var i = 0; i < BluezQt.Manager.devices.length; i++) {
            var dev = BluezQt.Manager.devices[i];
            if (dev && dev.connected) {
                res.push(dev);
            }
        }
        return res;
    }

    function getPairedDisconnectedDevices() {
        var dummy = _updateTrigger;
        if (!BluezQt.Manager || !BluezQt.Manager.devices) return [];
        var res = [];
        for (var i = 0; i < BluezQt.Manager.devices.length; i++) {
            var dev = BluezQt.Manager.devices[i];
            if (dev && dev.paired && !dev.connected) {
                res.push(dev);
            }
        }
        return res;
    }

    function getDiscoveredDevices() {
        var dummy = _updateTrigger;
        if (!BluezQt.Manager || !BluezQt.Manager.devices) return [];
        var res = [];
        for (var i = 0; i < BluezQt.Manager.devices.length; i++) {
            var dev = BluezQt.Manager.devices[i];
            var dName = dev.friendlyName || dev.name || "";
            // Ignore devices with blank or MAC-only names during scan for cleaner list
            if (dev && !dev.paired && !dev.connected && dName.length > 0 && !dName.match(/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/)) {
                res.push(dev);
            }
        }
        return res;
    }

    readonly property var connectedList: getConnectedDevices()
    readonly property var pairedList: getPairedDisconnectedDevices()
    readonly property var discoveredList: getDiscoveredDevices()
    readonly property var otherDevicesList: pairedList.concat(discoveredList)

    readonly property int totalDevicesCount: connectedList.length + otherDevicesList.length
    readonly property bool shouldShowSeeAll: !isExpanded && totalDevicesCount > 4
    readonly property int maxVisibleOther: connectedList.length > 0 ? 2 : 3

    onVisibleChanged: {
        if (visible) {
            if (fullRep && fullRep.isBtOn && BluezQt.Manager && BluezQt.Manager.usableAdapter) {
                try {
                    BluezQt.Manager.usableAdapter.startDiscovery();
                } catch (e) {
                    // ignore if already discovering
                }
            }
        } else {
            isExpanded = false;
        }
    }

    implicitHeight: viewHeader.height + scrollView.anchors.topMargin + contentCol.implicitHeight

    // Top Sticky Header (identyczny jak w WifiDetailsView)
    Rectangle {
        id: viewHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: headerCol.anchors.topMargin + headerCol.implicitHeight + snap(8.0)
        color: "transparent"
        z: 10

        // Back Arrow Button (Left)
        Rectangle {
            id: backBtn
            anchors.left: parent.left
            anchors.top: parent.top
            width: snap(32.0)  // 40px fizycznych
            height: snap(32.0) // 40px fizycznych
            radius: snap(8.0)
            color: backMouse.pressed
                   ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
                   : (backMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1) : "transparent")

            Kirigami.Icon {
                anchors.centerIn: parent
                width: snap(24.0) // 30px fizycznych
                height: snap(24.0)
                source: Qt.resolvedUrl("icons/arrow_back.svg")
                isMask: true
                color: Kirigami.Theme.textColor
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    bluetoothViewRoot.closeRequested();
                }
            }
        }

        // Center Titles & Separator
        ColumnLayout {
            id: headerCol
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: snap((backBtn.height - btLabel.implicitHeight) / 2)
            spacing: snap(4.8) // 6px fizycznych

            PlasmaComponents3.Label {
                id: btLabel
                text: i18n("Bluetooth")
                font.family: bluetoothViewRoot.appFontFamily
                font.bold: true
                font.pixelSize: snap(12.0) // 15px fizycznych
                color: Kirigami.Theme.textColor
                Layout.alignment: Qt.AlignHCenter
            }

            PlasmaComponents3.Label {
                text: i18n("Tap a device to connect")
                font.family: bluetoothViewRoot.appFontFamily
                font.pixelSize: snap(9.6) // 12px fizycznych
                color: Kirigami.Theme.disabledTextColor
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.topMargin: snap(4.8) // 12px fizycznych odstępu od napisu
                Layout.preferredWidth: snap(136.8) // 171px fizycznych
                Layout.preferredHeight: snap(4.0)   // 5px fizycznych
                Layout.alignment: Qt.AlignHCenter
                radius: snap(2.0)
                color: fullRep ? fullRep.oneUiTrackBg : Kirigami.Theme.alternateBackgroundColor
            }
        }

        // Scan / Refresh Button (Right Top)
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            width: snap(32.0)  // 40px fizycznych
            height: snap(32.0) // 40px fizycznych
            radius: snap(8.0)
            visible: Boolean(fullRep ? fullRep.isBtOn : true)
            color: scanMouse.pressed
                   ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
                   : (scanMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1) : "transparent")

            Kirigami.Icon {
                id: refreshIcon
                anchors.centerIn: parent
                width: snap(25.6) // 32px fizyczne
                height: snap(25.6)
                source: Qt.resolvedUrl("icons/refresh.svg")
                isMask: true
                color: Kirigami.Theme.textColor

                RotationAnimation on rotation {
                    running: bluetoothViewRoot.isDiscovering
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }

            MouseArea {
                id: scanMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (BluezQt.Manager && BluezQt.Manager.usableAdapter) {
                        try {
                            BluezQt.Manager.usableAdapter.startDiscovery();
                        } catch (e) {
                            console.warn("BT discovery error:", e);
                        }
                    }
                }
            }
        }
    }

    // Scrollable Content
    QQC2.ScrollView {
        id: scrollView
        anchors.top: viewHeader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: snap(8.0)
        clip: true
        contentWidth: availableWidth
        QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AlwaysOff
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

        ColumnLayout {
            id: contentCol
            width: scrollView.availableWidth
            spacing: 0

            // === 1. WHEN BLUETOOTH IS DISABLED ===
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                radius: 16
                color: fullRep ? fullRep.oneUiTrackBg : Kirigami.Theme.alternateBackgroundColor
                visible: fullRep ? !fullRep.isBtOn : false

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Kirigami.Icon {
                        source: "preferences-system-bluetooth"
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        Layout.alignment: Qt.AlignHCenter
                        opacity: 0.4
                        color: Kirigami.Theme.textColor
                    }

                    PlasmaComponents3.Label {
                        text: i18n("Bluetooth is turned off")
                        font.family: bluetoothViewRoot.appFontFamily
                        font.bold: true
                        font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.15)
                        color: Kirigami.Theme.textColor
                        Layout.alignment: Qt.AlignHCenter
                    }

                    PlasmaComponents3.Label {
                        text: i18n("Turn on Bluetooth to connect to devices.")
                        font.family: bluetoothViewRoot.appFontFamily
                        font.pixelSize: Math.round(Kirigami.Theme.smallFont.pixelSize * 1.05)
                        color: Kirigami.Theme.disabledTextColor
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 36
                        Layout.preferredWidth: 160
                        radius: 18
                        color: fullRep ? fullRep.effectiveAccentColor : Kirigami.Theme.highlightColor

                        PlasmaComponents3.Label {
                            anchors.centerIn: parent
                            text: i18n("Turn on Bluetooth")
                            font.family: bluetoothViewRoot.appFontFamily
                            font.bold: true
                            color: Kirigami.Theme.highlightedTextColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (BluezQt.Manager && BluezQt.Manager.usableAdapter) {
                                    BluezQt.Manager.usableAdapter.powered = true;
                                }
                            }
                        }
                    }
                }
            }

            // === 2. WHEN BLUETOOTH IS ENABLED ===
            ColumnLayout {
                Layout.fillWidth: true
                spacing: snap(1.6) // 2px fizycznych odstępu między kafelkami
                visible: fullRep ? Boolean(fullRep.isBtOn) : true

                // Bluetooth Label + Material 3 Switch Row
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: snap(32.0) // 40px fizycznych
                    Layout.topMargin: snap(14.4)       // 18px fizycznych odstępu od separatora
                    Layout.leftMargin: snap(19.2)      // wyrównanie z Wi-Fi
                    Layout.rightMargin: snap(19.2)
                    Layout.bottomMargin: snap(14.4)

                    PlasmaComponents3.Label {
                        text: i18n("Bluetooth")
                        font.family: bluetoothViewRoot.appFontFamily
                        font.bold: true
                        font.pixelSize: snap(12.0) // 15px fizycznych
                        color: Kirigami.Theme.textColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Material 3 Expressive Switch
                    Item {
                        id: m3Switch
                        Layout.preferredWidth: snap(36.8)  // 46px fizycznych
                        Layout.preferredHeight: snap(22.4) // 28px fizycznych
                        Layout.alignment: Qt.AlignVCenter

                        readonly property bool checked: Boolean(fullRep ? fullRep.isBtOn : false)

                        Rectangle {
                            id: switchTrack
                            anchors.fill: parent
                            radius: height / 2.0
                            color: m3Switch.checked
                                   ? (fullRep ? fullRep.effectiveAccentColor : Kirigami.Theme.highlightColor)
                                   : (fullRep ? fullRep.oneUiTrackBg : Kirigami.Theme.alternateBackgroundColor)
                            border.width: m3Switch.checked ? 0 : 1.5
                            border.color: fullRep ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.28) : Kirigami.Theme.separatorColor

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Rectangle {
                                id: switchThumb
                                height: m3Switch.checked ? snap(16.8) : snap(11.2) // 21px vs 14px
                                width: height
                                radius: height / 2.0
                                anchors.verticalCenter: parent.verticalCenter
                                x: m3Switch.checked
                                   ? (parent.width - width - snap(2.8))
                                   : snap(3.6)

                                color: m3Switch.checked
                                       ? (Kirigami.Theme.highlightedTextColor)
                                       : (Kirigami.Theme.textColor)

                                Behavior on x {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                Behavior on height {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: snap(9.6)
                                    height: snap(9.6)
                                    source: Qt.resolvedUrl("icons/check.svg")
                                    isMask: true
                                    color: fullRep ? fullRep.effectiveAccentColor : Kirigami.Theme.highlightColor
                                    opacity: m3Switch.checked ? 1.0 : 0.0
                                    visible: opacity > 0.0

                                    Behavior on opacity {
                                        NumberAnimation { duration: 150 }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: switchMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (BluezQt.Manager && BluezQt.Manager.usableAdapter) {
                                    BluezQt.Manager.usableAdapter.powered = !m3Switch.checked;
                                }
                            }
                        }
                    }
                }

                // Active connected device tile (jeśli jest)
                Rectangle {
                    id: activeDevTile
                    Layout.fillWidth: true
                    Layout.preferredHeight: snap(64.8) // 81px fizycznych
                    radius: 16
                    topLeftRadius: 16
                    topRightRadius: 16
                    bottomLeftRadius: 16
                    bottomRightRadius: 16
                    visible: bluetoothViewRoot.connectedList.length > 0
                    color: fullRep ? fullRep.effectiveAccentColor : Kirigami.Theme.highlightColor

                    readonly property var activeDev: bluetoothViewRoot.connectedList.length > 0 ? bluetoothViewRoot.connectedList[0] : null
                    readonly property string devName: (activeDev && (activeDev.friendlyName || activeDev.name) ? (activeDev.friendlyName || activeDev.name) : "").trim()
                    readonly property bool isPixelBuds: devName.indexOf("Pixel Buds") === 0
                    readonly property color onPrimaryColor: Kirigami.Theme.highlightedTextColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: snap(18.4)  // 23px fizyczne
                        anchors.rightMargin: snap(17.6) // 22px fizyczne
                        spacing: 12

                        // Czysta ikona urządzenia 22px (bez kwadratowego badge)
                        Item {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                visible: activeDevTile.isPixelBuds
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                source: Qt.resolvedUrl("assets/pixel_buds.png")
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }

                            Kirigami.Icon {
                                visible: !activeDevTile.isPixelBuds
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                source: (activeDevTile.activeDev && activeDevTile.activeDev.icon) ? activeDevTile.activeDev.icon : "preferences-system-bluetooth"
                                color: activeDevTile.onPrimaryColor
                            }
                        }

                        // Title + Status
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: snap(2.4)

                            PlasmaComponents3.Label {
                                text: activeDevTile.devName
                                font.family: bluetoothViewRoot.appFontFamily
                                font.bold: false
                                font.weight: Font.DemiBold // waga 600
                                font.pixelSize: snap(12.4) // 15.5px fizycznych
                                color: activeDevTile.onPrimaryColor
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            PlasmaComponents3.Label {
                                text: {
                                    if (activeDevTile.activeDev && activeDevTile.activeDev.battery) {
                                        return i18n("Connected") + " • " + activeDevTile.activeDev.battery.percentage + "%";
                                    }
                                    return i18n("Connected");
                                }
                                font.family: bluetoothViewRoot.appFontFamily
                                font.pixelSize: snap(9.6) // 12px fizycznych
                                color: Qt.rgba(activeDevTile.onPrimaryColor.r, activeDevTile.onPrimaryColor.g, activeDevTile.onPrimaryColor.b, 0.92)
                                Layout.fillWidth: true
                            }
                        }

                        // Przycisk Disconnect
                        Rectangle {
                            Layout.preferredWidth: snap(56.0) // 70px fizycznych
                            Layout.preferredHeight: snap(24.0) // 30px fizycznych
                            radius: height / 2.0
                            Layout.alignment: Qt.AlignVCenter
                            color: disconnBtMouse.pressed
                                   ? Qt.rgba(0, 0, 0, 0.25)
                                   : (disconnBtMouse.containsMouse ? Qt.rgba(0, 0, 0, 0.15) : Qt.rgba(0, 0, 0, 0.08))

                            PlasmaComponents3.Label {
                                anchors.centerIn: parent
                                text: i18n("Disconnect")
                                font.family: bluetoothViewRoot.appFontFamily
                                font.weight: Font.Medium
                                font.pixelSize: snap(9.6)
                                color: activeDevTile.onPrimaryColor
                            }

                            MouseArea {
                                id: disconnBtMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    try {
                                        if (activeDevTile.activeDev) activeDevTile.activeDev.disconnectFromDevice();
                                    } catch (e) {
                                        console.warn("BT disconnect error:", e);
                                    }
                                }
                            }
                        }

                        // Ikonka ustawień
                        Rectangle {
                            Layout.preferredWidth: snap(28.8) // 36px fizycznych
                            Layout.preferredHeight: snap(28.8)
                            Layout.alignment: Qt.AlignVCenter
                            radius: snap(7.2)
                            color: activeSettingsBtMouse.pressed ? Qt.rgba(0, 0, 0, 0.25)
                                                                 : (activeSettingsBtMouse.containsMouse ? Qt.rgba(0, 0, 0, 0.15) : "transparent")

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: snap(22.4)  // 28px fizycznych
                                height: snap(22.4)
                                source: Qt.resolvedUrl("icons/settings1.svg")
                                isMask: true
                                color: activeDevTile.onPrimaryColor
                            }

                            MouseArea {
                                id: activeSettingsBtMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    KCMUtils.KCMLauncher.openSystemSettings("kcm_bluetooth");
                                    if (bluetoothViewRoot.fullRep && bluetoothViewRoot.fullRep.appletRoot) {
                                        bluetoothViewRoot.fullRep.appletRoot.expanded = false;
                                    }
                                }
                            }
                        }
                    }
                }

                // Available & Saved Devices Repeater
                Repeater {
                    model: bluetoothViewRoot.otherDevicesList

                    delegate: Rectangle {
                        id: otherDevDelegate
                        required property var modelData
                        required property int index

                        readonly property string dName: (modelData && (modelData.friendlyName || modelData.name) ? (modelData.friendlyName || modelData.name) : "").trim()
                        readonly property bool isPixelBuds: dName.indexOf("Pixel Buds") === 0

                        readonly property int otherIdx: index
                        readonly property int otherTotal: bluetoothViewRoot.otherDevicesList.length
                        readonly property bool isSingleItem: otherTotal <= 1
                        readonly property bool isFirstItem: otherIdx === 0
                        readonly property bool isLastItem: otherIdx === (otherTotal - 1)

                        visible: !bluetoothViewRoot.shouldShowSeeAll || otherIdx < bluetoothViewRoot.maxVisibleOther

                        Layout.fillWidth: true
                        Layout.preferredHeight: snap(64.8) // 81px fizycznych
                        radius: 1
                        topLeftRadius: (isSingleItem || isFirstItem) ? 16 : 1
                        topRightRadius: (isSingleItem || isFirstItem) ? 16 : 1
                        bottomLeftRadius: (!bluetoothViewRoot.shouldShowSeeAll && (isSingleItem || isLastItem)) ? 16 : 1
                        bottomRightRadius: (!bluetoothViewRoot.shouldShowSeeAll && (isSingleItem || isLastItem)) ? 16 : 1
                        color: otherMouse.pressed
                               ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.16)
                               : (otherMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08) : (fullRep ? fullRep.oneUiTrackBg : Kirigami.Theme.alternateBackgroundColor))

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: snap(18.4)  // 23px fizyczne
                            anchors.rightMargin: snap(17.6) // 22px fizyczne
                            spacing: 12

                            // Czysta ikona urządzenia 22px
                            Item {
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                Layout.alignment: Qt.AlignVCenter

                                Image {
                                    visible: otherDevDelegate.isPixelBuds
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    source: Qt.resolvedUrl("assets/pixel_buds.png")
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                }

                                Kirigami.Icon {
                                    visible: !otherDevDelegate.isPixelBuds
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    source: (modelData && modelData.icon) ? modelData.icon : "preferences-system-bluetooth"
                                    color: Kirigami.Theme.textColor
                                }
                            }

                            // Device Title
                            PlasmaComponents3.Label {
                                text: otherDevDelegate.dName
                                font.family: bluetoothViewRoot.appFontFamily
                                font.bold: false
                                font.weight: Font.DemiBold // waga 600
                                font.pixelSize: snap(12.4) // 15.5px fizycznych
                                color: Kirigami.Theme.textColor
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Battery indicator jeśli urządzenie sparowane zgłasza poziom naładowania
                            PlasmaComponents3.Label {
                                visible: modelData && modelData.battery !== null
                                text: modelData && modelData.battery ? (modelData.battery.percentage + "%") : ""
                                font.family: bluetoothViewRoot.appFontFamily
                                font.pixelSize: snap(9.6)
                                color: Kirigami.Theme.disabledTextColor
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: otherMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                try {
                                    modelData.connectToDevice();
                                } catch (e) {
                                    console.warn("BT connect error:", e);
                                }
                            }
                        }
                    }
                }

                // "See all" Tile (shown when shouldShowSeeAll)
                Rectangle {
                    id: seeAllBtTile
                    Layout.fillWidth: true
                    Layout.preferredHeight: snap(64.8) // 81px fizycznych
                    radius: 1
                    topLeftRadius: 1
                    topRightRadius: 1
                    bottomLeftRadius: 16
                    bottomRightRadius: 16
                    visible: bluetoothViewRoot.shouldShowSeeAll
                    color: seeAllBtMouse.pressed
                           ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.16)
                           : (seeAllBtMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08) : (fullRep ? fullRep.oneUiTrackBg : Kirigami.Theme.alternateBackgroundColor))

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: snap(18.4)  // 23px fizyczne
                        anchors.rightMargin: snap(17.6) // 22px fizyczne
                        spacing: 12

                        Kirigami.Icon {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            Layout.alignment: Qt.AlignVCenter
                            source: Qt.resolvedUrl("icons/arrow_right.svg")
                            isMask: true
                            color: Kirigami.Theme.textColor
                        }

                        PlasmaComponents3.Label {
                            text: i18n("See all")
                            font.family: bluetoothViewRoot.appFontFamily
                            font.bold: false
                            font.weight: Font.Medium
                            font.pixelSize: snap(12.4)
                            color: Kirigami.Theme.textColor
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: seeAllBtMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            bluetoothViewRoot.isExpanded = true;
                        }
                    }
                }
            }

            // === 3. BOTTOM MORE SETTINGS ACTION ===
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: snap(36.0) // 45px fizycznych
                Layout.topMargin: snap(80.0)       // 100px fizycznych odstępu
                radius: height / 2.0               // pełna kapsułka / pill
                color: moreBtMouse.pressed
                       ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
                       : (moreBtMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08) : (fullRep ? fullRep.oneUiTrackBg : Kirigami.Theme.alternateBackgroundColor))

                RowLayout {
                    anchors.centerIn: parent
                    spacing: snap(8.0) // 10px fizycznych

                    Kirigami.Icon {
                        Layout.preferredWidth: snap(16.0) // 20px fizycznych
                        Layout.preferredHeight: snap(16.0)
                        Layout.alignment: Qt.AlignVCenter
                        source: Qt.resolvedUrl("icons/settings.svg")
                        isMask: true
                        color: Kirigami.Theme.textColor
                    }

                    PlasmaComponents3.Label {
                        text: i18n("More Bluetooth settings...")
                        font.family: bluetoothViewRoot.appFontFamily
                        font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.0)
                        color: Kirigami.Theme.textColor
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: moreBtMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        KCMUtils.KCMLauncher.openSystemSettings("kcm_bluetooth");
                        if (bluetoothViewRoot.fullRep && bluetoothViewRoot.fullRep.appletRoot) {
                            bluetoothViewRoot.fullRep.appletRoot.expanded = false;
                        }
                    }
                }
            }
        }
    }
}

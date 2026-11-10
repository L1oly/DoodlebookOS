import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.kcmutils as KCMUtils
import "i18n.js" as I18n

Item {
    id: wifiViewRoot

    function i18n(k, a1, a2) { return I18n.t(k, a1, a2); }

    property var fullRep: null
    property string selectedSsidToConnect: ""
    property string passwordInput: ""
    property bool showPassword: false

    readonly property string appFontFamily: "Google Sans Flex"

    property bool isExpanded: false
    readonly property int totalNetworksCount: (currentConnFinder && currentConnFinder.hasActive ? 1 : 0) + visibleNetworksTracker.names.length
    readonly property bool shouldShowSeeAll: !isExpanded && totalNetworksCount > 4
    readonly property int maxVisibleAvailable: (currentConnFinder && currentConnFinder.hasActive) ? 2 : 3

    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1.0
    function snap(val) {
        return Math.round(val * dpr) / dpr;
    }

    function wifiSignalIcon(signal) {
        var sig = (signal !== undefined && signal !== null) ? Number(signal) : 0;
        if (sig <= 0) return Qt.resolvedUrl("icons/wifi_0.svg");
        if (sig <= 33) return Qt.resolvedUrl("icons/wifi_1.svg");
        if (sig <= 66) return Qt.resolvedUrl("icons/wifi_2.svg");
        return Qt.resolvedUrl("icons/wifi_3.svg");
    }

    implicitHeight: viewHeader.height + scrollView.anchors.topMargin + contentCol.implicitHeight

    signal closeRequested()

    PlasmaNM.Handler {
        id: nmHandler
    }

    PlasmaNM.EnabledConnections {
        id: nmEnabled
    }

    Component {
        id: nmComponent
        PlasmaNM.NetworkModel {}
    }

    property var networkModel: null

    PlasmaNM.AppletProxyModel {
        id: appletProxyModel
    }

    Item {
        id: visibleNetworksTracker
        property var names: []

        function refresh() {
            var list = [];
            var count = appletProxyModel.rowCount();
            for (var i = 0; i < count; i++) {
                var idx = appletProxyModel.index(i, 0);
                var n = appletProxyModel.data(idx, PlasmaNM.NetworkModel.NameRole) || "";
                var st = appletProxyModel.data(idx, PlasmaNM.NetworkModel.ConnectionStateRole);
                if (n.length > 0 && st !== PlasmaNM.Enums.Activated) {
                    list.push(n);
                }
            }
            names = list;
        }

        Connections {
            target: appletProxyModel
            function onDataChanged() { visibleNetworksTracker.refresh(); }
            function onRowsInserted() { visibleNetworksTracker.refresh(); }
            function onRowsRemoved() { visibleNetworksTracker.refresh(); }
            function onModelReset() { visibleNetworksTracker.refresh(); }
        }
    }

    onVisibleChanged: {
        if (visible) {
            if (!networkModel) {
                networkModel = nmComponent.createObject(wifiViewRoot);
                appletProxyModel.sourceModel = networkModel;
            }
            nmHandler.requestScan();
            visibleNetworksTracker.refresh();
        } else {
            isExpanded = false;
            selectedSsidToConnect = "";
            passwordInput = "";
            showPassword = false;
        }
    }

    // Top Sticky Header
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
                width: snap(24.0) // 30px fizycznych (powiększona o 5px z 25px)
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
                    wifiViewRoot.closeRequested();
                }
            }
        }

        // Center Titles & Separator
        ColumnLayout {
            id: headerCol
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: snap((backBtn.height - internetLabel.implicitHeight) / 2)
            spacing: snap(4.8) // dokładnie 6px fizycznych (dwukrotnie więcej niż dotychczasowe 3px)

            PlasmaComponents3.Label {
                id: internetLabel
                text: i18n("Internet")
                font.family: wifiViewRoot.appFontFamily
                font.bold: true
                font.pixelSize: snap(12.0) // 15px fizycznych (zwiększone o 1px)
                color: Kirigami.Theme.textColor
                Layout.alignment: Qt.AlignHCenter
            }

            PlasmaComponents3.Label {
                text: i18n("Tap a network to connect")
                font.family: wifiViewRoot.appFontFamily
                font.pixelSize: snap(9.6) // 12px fizycznych
                color: Kirigami.Theme.disabledTextColor
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.topMargin: snap(4.8) // dodatkowe 6px fizycznych (łącznie 12px fizycznych odstępu od napisu)
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
            visible: Boolean(nmEnabled.wirelessEnabled)
            color: scanMouse.pressed
                   ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
                   : (scanMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1) : "transparent")

            Kirigami.Icon {
                id: refreshIcon
                anchors.centerIn: parent
                width: snap(25.6) // 32px fizyczne (powiększona o 8px z 24px)
                height: snap(25.6)
                source: Qt.resolvedUrl("icons/refresh.svg")
                isMask: true
                color: Kirigami.Theme.textColor

                RotationAnimation on rotation {
                    running: nmHandler.scanning
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
                onClicked: {
                    nmHandler.requestScan();
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

            // === 1. WHEN WI-FI IS DISABLED ===
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                radius: 16
                color: fullRep ? fullRep.oneUiTrackBg : Kirigami.Theme.alternateBackgroundColor
                visible: !nmEnabled.wirelessEnabled

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Kirigami.Icon {
                        source: Qt.resolvedUrl("icons/wifi_panel.svg")
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        Layout.alignment: Qt.AlignHCenter
                        opacity: 0.4
                        isMask: true
                        color: Kirigami.Theme.textColor
                    }

                    PlasmaComponents3.Label {
                        text: i18n("Wi-Fi is off")
                        font.family: wifiViewRoot.appFontFamily
                        font.bold: true
                        font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.15)
                        color: Kirigami.Theme.textColor
                        Layout.alignment: Qt.AlignHCenter
                    }

                    PlasmaComponents3.Label {
                        text: i18n("Turn on Wi-Fi to see available networks.")
                        font.family: wifiViewRoot.appFontFamily
                        font.pixelSize: Math.round(Kirigami.Theme.smallFont.pixelSize * 1.05)
                        color: Kirigami.Theme.disabledTextColor
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 36
                        Layout.preferredWidth: 130
                        radius: 18
                        color: fullRep ? fullRep.effectiveAccentColor : Kirigami.Theme.highlightColor

                        PlasmaComponents3.Label {
                            anchors.centerIn: parent
                            text: i18n("Turn on Wi-Fi")
                            font.family: wifiViewRoot.appFontFamily
                            font.bold: true
                            color: Kirigami.Theme.highlightedTextColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                nmHandler.enableWireless(true);
                            }
                        }
                    }
                }
            }

            // === 2. WHEN WI-FI IS ENABLED ===
            ColumnLayout {
                Layout.fillWidth: true
                spacing: snap(1.6) // 2px fizycznych odstępu między wszystkimi kafelkami sieci
                visible: Boolean(nmEnabled.wirelessEnabled)

                // Wi-Fi Label + Material 3 Switch Row
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: snap(32.0) // 40px fizycznych
                    Layout.topMargin: snap(14.4)       // dokładnie o 18px fizycznych (14.4 dp) większy odstęp od separatora
                    Layout.leftMargin: snap(19.2)      // 24px z kafelka + 18px z okna = 42px fizyczne od lewej krawędzi
                    Layout.rightMargin: snap(19.2)     // 24px z kafelka + 18px z okna = 42px fizyczne od prawej krawędzi
                    Layout.bottomMargin: snap(14.4)    // 18px fizycznych (14.4 dp) odstępu do pierwszego kafelka sieci

                    PlasmaComponents3.Label {
                        text: i18n("Wi-Fi")
                        font.family: wifiViewRoot.appFontFamily
                        font.bold: true
                        font.pixelSize: snap(12.0) // 15px fizycznych (zwiększone o 1px)
                        color: Kirigami.Theme.textColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Material 3 Expressive Switch
                    Item {
                        id: m3Switch
                        Layout.preferredWidth: snap(36.8)  // 46px fizycznych szerokości szyny M3
                        Layout.preferredHeight: snap(22.4) // dokładnie 28px fizycznych wysokości szyny M3
                        Layout.alignment: Qt.AlignVCenter

                        readonly property bool checked: Boolean(nmEnabled.wirelessEnabled)

                        // Track (Szyna kapsułkowa)
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

                            // Thumb (Gałka M3 powiększająca się i przesuwająca)
                            Rectangle {
                                id: switchThumb
                                height: m3Switch.checked ? snap(16.8) : snap(11.2) // 21px vs 14px fizyczne
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

                                // Checkmark icon wewnątrz gałki po włączeniu
                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: snap(9.6) // 12px fizycznych
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
                                nmHandler.enableWireless(!m3Switch.checked);
                            }
                        }
                    }
                }

                // Finder for active connection
                Item {
                    id: currentConnFinder
                    property bool hasActive: false
                    property string activeName: ""
                    property string activeConnPath: ""
                    property string activeDevPath: ""
                    property int activeSignalInt: 0
                    property int activeSecType: 0
                    property bool isSecured: false

                    function updateActive() {
                        var count = appletProxyModel.rowCount();
                        for (var i = 0; i < count; i++) {
                            var idx = appletProxyModel.index(i, 0);
                            var state = appletProxyModel.data(idx, PlasmaNM.NetworkModel.ConnectionStateRole);
                            if (state === PlasmaNM.Enums.Activated) {
                                activeName = appletProxyModel.data(idx, PlasmaNM.NetworkModel.NameRole) || "";
                                activeConnPath = appletProxyModel.data(idx, PlasmaNM.NetworkModel.ConnectionPathRole) || "";
                                activeDevPath = appletProxyModel.data(idx, PlasmaNM.NetworkModel.DevicePathRole) || "";
                                var sig = appletProxyModel.data(idx, PlasmaNM.NetworkModel.SignalRole);
                                activeSignalInt = (sig !== undefined && sig !== null) ? Number(sig) : 0;
                                var sec = appletProxyModel.data(idx, PlasmaNM.NetworkModel.SecurityTypeRole);
                                activeSecType = (sec !== undefined && sec !== null) ? Number(sec) : 0;
                                isSecured = (activeSecType !== PlasmaNM.Enums.None);
                                hasActive = (activeName.length > 0);
                                return;
                            }
                        }
                        hasActive = false;
                        activeName = "";
                        activeConnPath = "";
                        activeDevPath = "";
                        activeSignalInt = 0;
                        activeSecType = 0;
                        isSecured = false;
                    }

                    Connections {
                        target: appletProxyModel
                        function onDataChanged() { currentConnFinder.updateActive(); }
                        function onRowsInserted() { currentConnFinder.updateActive(); }
                        function onRowsRemoved() { currentConnFinder.updateActive(); }
                        function onModelReset() { currentConnFinder.updateActive(); }
                    }
                }

                // Active connected network tile (if any)
                Rectangle {
                    id: activeNetTile
                    Layout.fillWidth: true
                    Layout.preferredHeight: snap(64.8) // 81px fizycznych
                    radius: 16
                    topLeftRadius: 16
                    topRightRadius: 16
                    bottomLeftRadius: 16
                    bottomRightRadius: 16
                    visible: Boolean(currentConnFinder.hasActive)
                    color: fullRep ? fullRep.effectiveAccentColor : Kirigami.Theme.highlightColor

                    readonly property color onPrimaryColor: Kirigami.Theme.highlightedTextColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: snap(18.4)  // 23px fizyczne (zwiększone o 8px z 15px)
                        anchors.rightMargin: snap(17.6) // 22px fizyczne (zwiększone o 7px z 15px)
                        spacing: 12

                        // Wi-Fi Signal Icon (z gradientem/stopniami siły sygnału)
                        Kirigami.Icon {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            Layout.alignment: Qt.AlignVCenter
                            source: wifiViewRoot.wifiSignalIcon(currentConnFinder.activeSignalInt)
                            isMask: true
                            color: activeNetTile.onPrimaryColor
                        }

                        // Network Title + Connected subtitle
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: snap(2.4) // 3px fizyczne

                            PlasmaComponents3.Label {
                                text: currentConnFinder.activeName
                                font.family: wifiViewRoot.appFontFamily
                                font.bold: false
                                font.weight: Font.DemiBold // waga 600
                                font.pixelSize: snap(12.4) // 15.5px fizycznych (jak w referencji)
                                color: activeNetTile.onPrimaryColor
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            PlasmaComponents3.Label {
                                text: i18n("Connected")
                                font.family: wifiViewRoot.appFontFamily
                                font.pixelSize: snap(9.6) // 12px fizycznych (jak w referencji)
                                color: Qt.rgba(activeNetTile.onPrimaryColor.r, activeNetTile.onPrimaryColor.g, activeNetTile.onPrimaryColor.b, 0.92)
                                Layout.fillWidth: true
                            }
                        }

                        // Ikonka ustawień po prawej stronie (settings1.svg) powiększona
                        Rectangle {
                            Layout.preferredWidth: snap(28.8) // 36px fizycznych
                            Layout.preferredHeight: snap(28.8)
                            Layout.alignment: Qt.AlignVCenter
                            radius: snap(7.2)
                            color: activeSettingsMouse.pressed ? Qt.rgba(0, 0, 0, 0.25)
                                                               : (activeSettingsMouse.containsMouse ? Qt.rgba(0, 0, 0, 0.15) : "transparent")

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: snap(22.4)  // 28px fizycznych (powiększona)
                                height: snap(22.4) // 28px fizycznych
                                source: Qt.resolvedUrl("icons/settings1.svg")
                                isMask: true
                                color: activeNetTile.onPrimaryColor
                            }

                            MouseArea {
                                id: activeSettingsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    KCMUtils.KCMLauncher.openSystemSettings("kcm_networkmanagement");
                                    if (wifiViewRoot.fullRep && wifiViewRoot.fullRep.appletRoot) {
                                        wifiViewRoot.fullRep.appletRoot.expanded = false;
                                    }
                                }
                            }
                        }
                    }
                }

                // Networks Repeater (Available networks)
                Repeater {
                    model: appletProxyModel

                    delegate: ColumnLayout {
                        id: networkDelegate
                        Layout.fillWidth: true
                        spacing: snap(1.6) // 2px fizycznych

                        readonly property string netName: model.Name || ""
                        readonly property int netSignal: (model.Signal !== undefined && model.Signal !== null) ? model.Signal : 0
                        readonly property int netState: (model.ConnectionState !== undefined) ? model.ConnectionState : 0
                        readonly property string netConnPath: model.ConnectionPath || ""
                        readonly property string netDevPath: model.DevicePath || ""
                        readonly property string netSpecPath: model.SpecificPath || ""
                        readonly property int netSecType: (model.SecurityType !== undefined) ? model.SecurityType : 0
                        readonly property bool isSecured: netSecType !== PlasmaNM.Enums.None
                        readonly property bool isActivated: netState === PlasmaNM.Enums.Activated
                        readonly property bool isActivating: netState === PlasmaNM.Enums.Activating
                        readonly property bool isPromptingPassword: wifiViewRoot.selectedSsidToConnect === netName

                        readonly property int visibleIdx: visibleNetworksTracker.names.indexOf(netName)
                        readonly property int visibleTotal: visibleNetworksTracker.names.length
                        readonly property bool isSingleItem: visibleTotal <= 1
                        readonly property bool isFirstItem: visibleIdx === 0
                        readonly property bool isLastItem: visibleIdx >= 0 && visibleIdx === (visibleTotal - 1)

                        visible: netName.length > 0 && !isActivated && (!wifiViewRoot.shouldShowSeeAll || visibleIdx < wifiViewRoot.maxVisibleAvailable)

                        // Network Tile Row
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: snap(64.8) // dokładnie 81px fizycznych (64.8 dp)
                            radius: 1
                            topLeftRadius: (networkDelegate.isSingleItem || networkDelegate.isFirstItem) ? 16 : 1
                            topRightRadius: (networkDelegate.isSingleItem || networkDelegate.isFirstItem) ? 16 : 1
                            bottomLeftRadius: (!wifiViewRoot.shouldShowSeeAll && (networkDelegate.isSingleItem || networkDelegate.isLastItem)) ? 16 : 1
                            bottomRightRadius: (!wifiViewRoot.shouldShowSeeAll && (networkDelegate.isSingleItem || networkDelegate.isLastItem)) ? 16 : 1
                            color: itemMouseArea.pressed
                                   ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.16)
                                   : (itemMouseArea.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08) : (fullRep ? fullRep.oneUiTrackBg : Kirigami.Theme.alternateBackgroundColor))

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: snap(18.4)  // 23px fizyczne (zwiększone o 8px z 15px)
                                anchors.rightMargin: snap(17.6) // 22px fizyczne (zwiększone o 7px z 15px)
                                spacing: 12

                                // Wi-Fi Signal Icon (ze stopniami siły sygnału)
                                Kirigami.Icon {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    Layout.alignment: Qt.AlignVCenter
                                    source: wifiViewRoot.wifiSignalIcon(networkDelegate.netSignal)
                                    isMask: true
                                    color: Kirigami.Theme.textColor
                                }

                                // Network Title Only (bez napisów z mocą i zabezpieczeniami)
                                PlasmaComponents3.Label {
                                    text: networkDelegate.netName
                                    font.family: wifiViewRoot.appFontFamily
                                    font.bold: false
                                    font.weight: Font.DemiBold // waga 600
                                    font.pixelSize: snap(12.4) // 15.5px fizycznych (jak w referencji)
                                    color: Kirigami.Theme.textColor
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                // Kłódka po prawej stronie kafelka (w identycznym kontenerze 36px jak ikona ustawień - idealna linia w pionie)
                                Item {
                                    Layout.preferredWidth: snap(28.8)  // 36px fizycznych
                                    Layout.preferredHeight: snap(28.8) // 36px fizycznych
                                    Layout.alignment: Qt.AlignVCenter
                                    visible: networkDelegate.isSecured

                                    Kirigami.Icon {
                                        anchors.centerIn: parent
                                        width: snap(22.4)  // 28px fizycznych (powiększona odrobinę z 27px)
                                        height: snap(22.4) // 28px fizycznych
                                        source: Qt.resolvedUrl("icons/custom_lock.svg")
                                        isMask: true
                                        color: Kirigami.Theme.disabledTextColor
                                    }
                                }

                                PlasmaComponents3.BusyIndicator {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    Layout.alignment: Qt.AlignVCenter
                                    running: networkDelegate.isActivating
                                    visible: networkDelegate.isActivating
                                }
                            }

                            MouseArea {
                                id: itemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (networkDelegate.isActivating) return;
                                    // If saved connection profile exists
                                    if (networkDelegate.netConnPath.length > 0) {
                                        nmHandler.activateConnection(networkDelegate.netConnPath, networkDelegate.netDevPath, networkDelegate.netSpecPath);
                                    } else if (!networkDelegate.isSecured) {
                                        // Open network without password
                                        nmHandler.addAndActivateConnection(networkDelegate.netDevPath, networkDelegate.netSpecPath);
                                    } else {
                                        // Password needed
                                        if (wifiViewRoot.selectedSsidToConnect === networkDelegate.netName) {
                                            wifiViewRoot.selectedSsidToConnect = "";
                                        } else {
                                            wifiViewRoot.selectedSsidToConnect = networkDelegate.netName;
                                            wifiViewRoot.passwordInput = "";
                                        }
                                    }
                                }
                            }
                        }

                        // Inline Password Input Card
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: pwdCol.implicitHeight + 20
                            radius: 12
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)
                            border.width: 1
                            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                            visible: networkDelegate.isPromptingPassword

                            ColumnLayout {
                                id: pwdCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                PlasmaComponents3.Label {
                                    text: i18n("Enter password for %1:", networkDelegate.netName)
                                    font.family: wifiViewRoot.appFontFamily
                                    font.bold: true
                                    font.pixelSize: Math.round(Kirigami.Theme.smallFont.pixelSize * 1.0)
                                    color: Kirigami.Theme.textColor
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    QQC2.TextField {
                                        id: pwdField
                                        Layout.fillWidth: true
                                        font.family: wifiViewRoot.appFontFamily
                                        placeholderText: i18n("Network password")
                                        echoMode: wifiViewRoot.showPassword ? TextInput.Normal : TextInput.Password
                                        text: wifiViewRoot.passwordInput
                                        onTextChanged: {
                                            wifiViewRoot.passwordInput = text;
                                        }
                                        onAccepted: {
                                            if (text.length > 0) {
                                                nmHandler.addAndActivateConnection(networkDelegate.netDevPath, networkDelegate.netSpecPath, text);
                                                wifiViewRoot.selectedSsidToConnect = "";
                                            }
                                        }
                                    }

                                    // Eye toggle
                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 6
                                        color: eyeMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12) : "transparent"

                                        Kirigami.Icon {
                                            anchors.centerIn: parent
                                            width: 18
                                            height: 18
                                            source: wifiViewRoot.showPassword ? "visibility" : "hint"
                                            color: Kirigami.Theme.textColor
                                        }

                                        MouseArea {
                                            id: eyeMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                wifiViewRoot.showPassword = !wifiViewRoot.showPassword;
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Item { Layout.fillWidth: true }

                                    PlasmaComponents3.Button {
                                        text: i18n("Cancel")
                                        font.family: wifiViewRoot.appFontFamily
                                        onClicked: {
                                            wifiViewRoot.selectedSsidToConnect = "";
                                        }
                                    }

                                    PlasmaComponents3.Button {
                                        text: i18n("Connect")
                                        font.family: wifiViewRoot.appFontFamily
                                        highlighted: true
                                        enabled: wifiViewRoot.passwordInput.length >= 8
                                        onClicked: {
                                            nmHandler.addAndActivateConnection(networkDelegate.netDevPath, networkDelegate.netSpecPath, wifiViewRoot.passwordInput);
                                            wifiViewRoot.selectedSsidToConnect = "";
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // "See all" Tile (shown when shouldShowSeeAll)
                Rectangle {
                    id: seeAllTile
                    Layout.fillWidth: true
                    Layout.preferredHeight: snap(64.8) // dokładnie 81px fizycznych (64.8 dp) - identyczna jak kafelki sieci
                    radius: 1
                    topLeftRadius: 1
                    topRightRadius: 1
                    bottomLeftRadius: 16
                    bottomRightRadius: 16
                    visible: wifiViewRoot.shouldShowSeeAll
                    color: seeAllMouse.pressed
                           ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.16)
                           : (seeAllMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08) : (fullRep ? fullRep.oneUiTrackBg : Kirigami.Theme.alternateBackgroundColor))

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: snap(18.4)  // 23px fizyczne
                        anchors.rightMargin: snap(17.6) // 22px fizyczne
                        spacing: 12

                        // Arrow right icon
                        Kirigami.Icon {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            Layout.alignment: Qt.AlignVCenter
                            source: Qt.resolvedUrl("icons/arrow_right.svg")
                            isMask: true
                            color: Kirigami.Theme.textColor
                        }

                        // "See all" label
                        PlasmaComponents3.Label {
                            text: i18n("See all")
                            font.family: wifiViewRoot.appFontFamily
                            font.bold: false
                            font.weight: Font.Medium // waga 500
                            font.pixelSize: snap(12.4) // 15.5px fizycznych
                            color: Kirigami.Theme.textColor
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: seeAllMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            wifiViewRoot.isExpanded = true;
                        }
                    }
                }
            }

            // === 3. BOTTOM MORE SETTINGS ACTION ===
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: snap(36.0) // dokładnie 45px fizycznych (36.0 dp)
                Layout.topMargin: snap(80.0)       // dokładnie 100px fizycznych odstępu (80.0 dp)
                radius: height / 2.0               // maksymalnie zaokrąglone rogi (pełna kapsułka / pill)
                color: moreNetMouse.pressed
                       ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
                       : (moreNetMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08) : (fullRep ? fullRep.oneUiTrackBg : Kirigami.Theme.alternateBackgroundColor))

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
                        text: i18n("More Wi-Fi settings")
                        font.family: wifiViewRoot.appFontFamily
                        font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.0)
                        color: Kirigami.Theme.textColor
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: moreNetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        KCMUtils.KCMLauncher.openSystemSettings("kcm_networkmanagement");
                        if (wifiViewRoot.fullRep && wifiViewRoot.fullRep.appletRoot) {
                            wifiViewRoot.fullRep.appletRoot.expanded = false;
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kcmutils as KCMUtils
import "i18n.js" as I18n

Item {
    id: powerViewRoot

    function i18n(k, a1, a2) { return I18n.t(k, a1, a2); }

    property var fullRep: null
    property var appletRoot: null

    readonly property string appFontFamily: "Google Sans Flex"

    signal closeRequested()

    readonly property var batteryModel: (appletRoot && appletRoot.batteryModel) ? appletRoot.batteryModel : null
    readonly property bool hasInternalBattery: (appletRoot && appletRoot.hasInternalBattery !== undefined)
        ? appletRoot.hasInternalBattery
        : (batteryModel ? Boolean(batteryModel.hasCumulative || (batteryModel.hasInternalBatteries && batteryModel.percent > 0)) : false)

    // Top Sticky Header
    Rectangle {
        id: viewHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 52
        color: "transparent"
        z: 10

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 10

            // Back Arrow Button
            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 10
                Layout.alignment: Qt.AlignVCenter
                color: backMouse.pressed
                       ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
                       : (backMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1) : "transparent")

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    source: Qt.resolvedUrl("icons/arrow_back.svg")
                    isMask: true
                    color: Kirigami.Theme.textColor
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        powerViewRoot.closeRequested();
                    }
                }
            }

            // Title
            PlasmaComponents3.Label {
                text: i18n("Power & battery")
                font.family: powerViewRoot.appFontFamily
                font.bold: true
                font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.35)
                color: Kirigami.Theme.textColor
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }
        }
    }

    // Scrollable Content
    QQC2.ScrollView {
        id: scrollView
        anchors.top: viewHeader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 8
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: scrollView.availableWidth
            spacing: 14

            // Battery Status Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: bCardCol.implicitHeight + 24
                radius: 16
                color: fullRep ? fullRep.oneUiTrackBg : Kirigami.Theme.alternateBackgroundColor

                ColumnLayout {
                    id: bCardCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // Battery Icon
                        Rectangle {
                            width: 42
                            height: 42
                            radius: 14
                            color: fullRep ? fullRep.effectiveAccentColor : Kirigami.Theme.highlightColor

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                source: (appletRoot && appletRoot.currentBatteryIcon) ? appletRoot.currentBatteryIcon : Qt.resolvedUrl("icons/battery_android_full_bolt.svg")
                                isMask: true
                                color: Kirigami.Theme.highlightedTextColor
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            PlasmaComponents3.Label {
                                text: {
                                    if (powerViewRoot.hasInternalBattery && batteryModel) {
                                        var st = "";
                                        if (batteryModel.state === 1) st = i18n("Charging");
                                        else if (batteryModel.state === 3) st = i18n("Fully charged");
                                        else if (batteryModel.pluggedIn) st = i18n("Connected to AC");
                                        else st = i18n("On battery");
                                        return i18n("%1% (%2)", batteryModel.percent, st);
                                    }
                                    return (batteryModel && batteryModel.pluggedIn)
                                        ? i18n("AC Power")
                                        : i18n("Connected to power");
                                }
                                font.family: powerViewRoot.appFontFamily
                                font.bold: true
                                font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.15)
                                color: Kirigami.Theme.textColor
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            PlasmaComponents3.Label {
                                text: {
                                    if (powerViewRoot.hasInternalBattery && batteryModel) {
                                        return batteryModel.pluggedIn
                                            ? i18n("Connected to power source")
                                            : i18n("Battery Power");
                                    }
                                    return i18n("Desktop computer or external power supply");
                                }
                                font.family: powerViewRoot.appFontFamily
                                font.pixelSize: Math.round(Kirigami.Theme.smallFont.pixelSize * 0.95)
                                color: Kirigami.Theme.disabledTextColor
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Progress bar
                    PlasmaComponents3.ProgressBar {
                        visible: powerViewRoot.hasInternalBattery
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: (batteryModel && batteryModel.percent !== undefined) ? batteryModel.percent : 100
                    }
                }
            }

            // Power Session Actions Card (matching power menu)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: sessionCol.implicitHeight + 16
                radius: 16
                color: fullRep ? fullRep.oneUiTrackBg : Kirigami.Theme.alternateBackgroundColor

                ColumnLayout {
                    id: sessionCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    component PowerActionItem: Rectangle {
                        id: actItem
                        property string title: ""
                        property string iconName: ""
                        signal triggered()

                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: 10
                        color: actMouse.pressed
                               ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
                               : (actMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08) : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Kirigami.Icon {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                source: actItem.iconName
                                isMask: true
                                color: Kirigami.Theme.textColor
                            }

                            PlasmaComponents3.Label {
                                text: actItem.title
                                font.family: powerViewRoot.appFontFamily
                                font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.0)
                                color: Kirigami.Theme.textColor
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: actMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: actItem.triggered()
                        }
                    }

                    PowerActionItem {
                        title: i18n("Log out")
                        iconName: Qt.resolvedUrl("icons/logout.svg")
                        onTriggered: {
                            if (fullRep) fullRep.requestLogout();
                        }
                    }

                    PowerActionItem {
                        title: i18n("Restart")
                        iconName: Qt.resolvedUrl("icons/restart.svg")
                        onTriggered: {
                            if (fullRep) fullRep.requestReboot();
                        }
                    }

                    PowerActionItem {
                        title: i18n("Shut down")
                        iconName: Qt.resolvedUrl("icons/power_btn.svg")
                        onTriggered: {
                            if (fullRep) fullRep.requestShutdown();
                        }
                    }
                }
            }

            // Bottom Settings Actions
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: 12
                color: morePwrMouse.pressed
                       ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
                       : (morePwrMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08) : (fullRep ? fullRep.oneUiTrackBg : Kirigami.Theme.alternateBackgroundColor))

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Kirigami.Icon {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        source: Qt.resolvedUrl("icons/settings.svg")
                        isMask: true
                        color: Kirigami.Theme.textColor
                    }

                    PlasmaComponents3.Label {
                        text: i18n("More power settings...")
                        font.family: powerViewRoot.appFontFamily
                        font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.0)
                        color: Kirigami.Theme.textColor
                        Layout.fillWidth: true
                    }

                    Kirigami.Icon {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        source: "go-next"
                        color: Kirigami.Theme.disabledTextColor
                    }
                }

                MouseArea {
                    id: morePwrMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        KCMUtils.KCMLauncher.openSystemSettings("kcm_powerdevilprofilesconfig");
                        if (powerViewRoot.fullRep && powerViewRoot.fullRep.appletRoot) {
                            powerViewRoot.fullRep.appletRoot.expanded = false;
                        }
                    }
                }
            }

            Item {
                Layout.preferredHeight: 16
            }
        }
    }
}

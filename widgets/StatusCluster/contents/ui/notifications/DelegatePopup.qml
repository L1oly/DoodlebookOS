/*
    SPDX-FileCopyrightText: 2026 DoodlebookOS
    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager

import "i18n.js" as I18n

Item {
    id: delegateRoot
    function i18n(k, a1, a2) { return I18n.t(k, a1, a2); }

    property ModelInterface modelInterface: ModelInterface {}

    property bool cardExpanded: true

    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1.0
    function snap(val) {
        return Math.round(val * dpr) / dpr;
    }

    Layout.preferredWidth: snap(309.6)
    Layout.preferredHeight: implicitHeight
    implicitWidth: snap(309.6)
    implicitHeight: cardRect.implicitHeight

    Accessible.role: Accessible.Notification
    Accessible.name: modelInterface.summary
    Accessible.description: modelInterface.accessibleDescription

    Binding {
        target: delegateRoot.modelInterface
        property: "replying"
        value: replyInput.activeFocus
    }
    Binding {
        target: delegateRoot.modelInterface
        property: "hasPendingReply"
        value: replyInput.text.length > 0
    }

    function formatRelativeTime(date) {
        if (!date || isNaN(date.getTime())) return "";
        var now = Date.now();
        var diffMs = now - date.getTime();
        if (diffMs < 0) return i18n("now");
        var diffSec = Math.floor(diffMs / 1000);
        if (diffSec < 60) return i18n("now");
        var diffMin = Math.floor(diffSec / 60);
        if (diffMin < 60) return diffMin + " " + i18n("min");
        var diffHours = Math.floor(diffMin / 60);
        if (diffHours < 24) return diffHours + " " + i18n("h");
        var diffDays = Math.floor(diffHours / 24);
        return diffDays + " " + i18n("d");
    }

    Item {
        id: buttonThemeScope
        Kirigami.Theme.colorSet: Kirigami.Theme.Button
        Kirigami.Theme.inherit: false
    }

    readonly property color cardBackgroundColor: buttonThemeScope ? buttonThemeScope.Kirigami.Theme.backgroundColor : Kirigami.Theme.backgroundColor

    Rectangle {
        id: cardRect
        width: parent.width
        height: cardInnerCol.implicitHeight + delegateRoot.snap(24)
        implicitHeight: height
        radius: delegateRoot.snap(20)
        color: delegateRoot.cardBackgroundColor

        HoverHandler {
            id: cardHover
        }

        // Hover & Press feedback overlay
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Kirigami.Theme.textColor
            opacity: cardBodyMouse.pressed ? 0.20 : (cardHover.hovered ? 0.08 : 0)
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
        }

        ColumnLayout {
            id: cardInnerCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: delegateRoot.snap(12)
            spacing: delegateRoot.snap(6)

            // Top row
            RowLayout {
                Layout.fillWidth: true
                spacing: delegateRoot.snap(10)

                // App Icon Badge
                Rectangle {
                    Layout.preferredWidth: delegateRoot.snap(36)
                    Layout.preferredHeight: delegateRoot.snap(36)
                    Layout.alignment: Qt.AlignTop
                    radius: width / 2
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)

                    Kirigami.Icon {
                        id: mainAppIcon
                        anchors.centerIn: parent
                        width: delegateRoot.snap(20)
                        height: width
                        readonly property string resolvedIconName: String(delegateRoot.modelInterface.icon || delegateRoot.modelInterface.applicationIconSource || "preferences-system-notifications")
                        source: delegateRoot.modelInterface.icon || delegateRoot.modelInterface.applicationIconSource || "preferences-system-notifications"
                        isMask: resolvedIconName.endsWith("-symbolic") || resolvedIconName === "preferences-system-notifications"
                        color: Kirigami.Theme.textColor
                        visible: !cardImg.visible
                    }

                    Kirigami.Icon {
                        id: cardImg
                        anchors.centerIn: parent
                        width: delegateRoot.snap(22)
                        height: width
                        source: delegateRoot.modelInterface.image || ""
                        visible: Boolean(delegateRoot.modelInterface.image) && valid
                    }
                }

                // Texts column
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 2

                    // App Name • Relative Time
                    Text {
                        Layout.fillWidth: true
                        text: {
                            var app = delegateRoot.modelInterface.applicationName || i18n("System");
                            var timeDate = delegateRoot.modelInterface.time;
                            var t = delegateRoot.formatRelativeTime(timeDate);
                            return t ? (app + " • " + t) : app;
                        }
                        font.pixelSize: 12
                        color: Kirigami.Theme.textColor
                        opacity: 0.75
                        elide: Text.ElideRight
                    }

                    // Summary / Title
                    Text {
                        Layout.fillWidth: true
                        text: delegateRoot.modelInterface.summary || delegateRoot.modelInterface.body || ""
                        font.weight: Font.DemiBold
                        font.pixelSize: 14
                        color: Kirigami.Theme.textColor
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        maximumLineCount: delegateRoot.cardExpanded ? 3 : 1
                        visible: text.length > 0
                    }

                    // Body
                    Text {
                        Layout.fillWidth: true
                        visible: delegateRoot.cardExpanded && delegateRoot.modelInterface.body && delegateRoot.modelInterface.body.length > 0 && delegateRoot.modelInterface.summary && delegateRoot.modelInterface.summary.length > 0
                        text: delegateRoot.modelInterface.body || ""
                        font.pixelSize: 13
                        color: Kirigami.Theme.textColor
                        opacity: 0.85
                        wrapMode: Text.Wrap
                        textFormat: Text.StyledText
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }

                    // Job progress bar (if JobType)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        height: 4
                        radius: 2
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                        visible: delegateRoot.modelInterface.notificationType === NotificationManager.Notifications.JobType

                        Rectangle {
                            width: parent.width * (Math.max(0, Math.min(100, delegateRoot.modelInterface.percentage || 0)) / 100)
                            height: parent.height
                            radius: 2
                            color: Kirigami.Theme.highlightColor
                        }
                    }
                }

                // Control buttons (close on hover + chevron)
                RowLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: delegateRoot.snap(3)

                    // Close button (visible on card hover)
                    // Close button (visible on hover)
                    Rectangle {
                        Layout.preferredWidth: delegateRoot.snap(26)
                        Layout.preferredHeight: delegateRoot.snap(26)
                        Layout.alignment: Qt.AlignVCenter
                        radius: width / 2
                        color: closeMouse.pressed
                               ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
                               : (closeMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.20) : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12))
                        visible: delegateRoot.modelInterface.closable || delegateRoot.modelInterface.dismissable
                        opacity: (cardHover.hovered || closeMouse.containsMouse || closeMouse.pressed || chevMouse.containsMouse) ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: delegateRoot.snap(13)
                            height: width
                            source: "window-close-symbolic"
                            color: Kirigami.Theme.textColor
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: delegateRoot.modelInterface.closeClicked()
                        }
                    }

                    // Chevron button (Elipsa 30x20 px fizycznych)
                    Rectangle {
                        Layout.preferredWidth: delegateRoot.snap(24)
                        Layout.preferredHeight: delegateRoot.snap(16)
                        Layout.alignment: Qt.AlignVCenter
                        radius: height / 2.0
                        color: chevMouse.pressed
                               ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
                               : (chevMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.20) : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12))
                        visible: delegateRoot.modelInterface.body && delegateRoot.modelInterface.body.length > 0 && delegateRoot.modelInterface.summary && delegateRoot.modelInterface.summary.length > 0

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: delegateRoot.snap(11)
                            height: width
                            source: delegateRoot.cardExpanded ? Qt.resolvedUrl("icons/chevron_up.svg") : Qt.resolvedUrl("icons/chevron_down.svg")
                            isMask: true
                            color: Kirigami.Theme.textColor
                        }

                        MouseArea {
                            id: chevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: delegateRoot.cardExpanded = !delegateRoot.cardExpanded
                        }
                    }
                }
            }

            // Action buttons Flow
            Flow {
                id: actionsFlow
                Layout.fillWidth: true
                Layout.leftMargin: delegateRoot.snap(46)
                Layout.topMargin: 2
                spacing: delegateRoot.snap(14)
                visible: delegateRoot.cardExpanded && delegateRoot.modelInterface.actionLabels && delegateRoot.modelInterface.actionLabels.length > 0
                width: cardRect.width - delegateRoot.snap(24) - delegateRoot.snap(46)

                Repeater {
                    model: (delegateRoot.cardExpanded && delegateRoot.modelInterface.actionLabels) ? delegateRoot.modelInterface.actionLabels : []
                    Item {
                        required property int index
                        required property string modelData

                        width: actText.implicitWidth
                        height: actText.implicitHeight

                        Text {
                            id: actText
                            text: parent.modelData
                            font.bold: true
                            font.pixelSize: 13
                            color: actMouse.containsMouse ? Kirigami.Theme.highlightColor : Kirigami.Theme.linkColor
                        }

                        MouseArea {
                            id: actMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                var actName = delegateRoot.modelInterface.actionNames[parent.index];
                                delegateRoot.modelInterface.actionInvoked(actName);
                            }
                        }
                    }
                }
            }

            // Inline reply field
            RowLayout {
                id: replyRow
                Layout.fillWidth: true
                Layout.leftMargin: 52
                Layout.topMargin: 4
                visible: delegateRoot.cardExpanded && delegateRoot.modelInterface.hasReplyAction
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 17
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)

                    TextInput {
                        id: replyInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        color: Kirigami.Theme.textColor
                        font.pixelSize: 13
                        clip: true
                        onAccepted: {
                            if (text.trim().length > 0) {
                                delegateRoot.modelInterface.replied(text.trim());
                                text = "";
                            }
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: delegateRoot.modelInterface.replyPlaceholderText || i18n("Reply…")
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.5)
                            font.pixelSize: 13
                            visible: !replyInput.text && !replyInput.activeFocus
                        }
                    }
                }

                Rectangle {
                    width: 34
                    height: 34
                    radius: 17
                    color: sendMouse.pressed
                           ? Qt.darker(Kirigami.Theme.highlightColor, 1.2)
                           : (sendMouse.containsMouse ? Qt.lighter(Kirigami.Theme.highlightColor, 1.15) : Kirigami.Theme.highlightColor)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        source: "document-send"
                        color: Kirigami.Theme.highlightedTextColor
                    }

                    MouseArea {
                        id: sendMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (replyInput.text.trim().length > 0) {
                                delegateRoot.modelInterface.replied(replyInput.text.trim());
                                replyInput.text = "";
                            }
                        }
                    }
                }
            }
        }

        // Card body click (invokes default action)
        MouseArea {
            id: cardBodyMouse
            anchors.fill: parent
            z: -1
            hoverEnabled: true
            cursorShape: delegateRoot.modelInterface.hasDefaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (delegateRoot.modelInterface.hasDefaultAction) {
                    delegateRoot.modelInterface.defaultActionInvoked();
                } else if (delegateRoot.modelInterface.urls && delegateRoot.modelInterface.urls.length === 1) {
                    Qt.openUrlExternally(delegateRoot.modelInterface.urls[0]);
                }
            }
        }
    }
}

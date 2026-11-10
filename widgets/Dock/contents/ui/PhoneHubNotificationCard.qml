/*
 * SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "i18n.js" as I18n

Rectangle {
    id: root

    function i18n(k, a1, a2) { return I18n.t(k, a1, a2); }

    property var notifModel: null
    property bool isReplying: false

    width: parent ? parent.width : 0
    implicitHeight: mainCol.implicitHeight + 24
    radius: 16
    color: Qt.rgba(1, 1, 1, 0.06)
    border.color: Qt.rgba(1, 1, 1, 0.08)
    border.width: 1

    ColumnLayout {
        id: mainCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        spacing: 6

        // 1. Header (Icon + App Name + Dismiss button)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Kirigami.Icon {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                source: (root.notifModel && root.notifModel.appIcon) ? root.notifModel.appIcon : "notifications"
            }

            Text {
                Layout.fillWidth: true
                text: (root.notifModel && root.notifModel.appName) ? root.notifModel.appName : ""
                font.family: "Google Sans Flex"
                font.pixelSize: 11
                font.weight: Font.Normal
                color: Qt.rgba(1, 1, 1, 0.60)
                elide: Text.ElideRight
            }

            // Dismiss Button (✕)
            Item {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: closeMa.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
                }

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.70)
                }

                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.notifModel) {
                            if (root.notifModel.dbusInterface && typeof root.notifModel.dbusInterface.dismiss === "function") {
                                root.notifModel.dbusInterface.dismiss();
                            } else if (typeof root.notifModel.dismiss === "function") {
                                root.notifModel.dismiss();
                            }
                        }
                    }
                }
            }
        }

        // 2. Title / Sender
        Text {
            Layout.fillWidth: true
            text: (root.notifModel && root.notifModel.title) ? root.notifModel.title : ""
            visible: text.length > 0
            font.family: "Google Sans Flex"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: "#FFFFFF"
            elide: Text.ElideRight
        }

        // 3. Message Body
        Text {
            Layout.fillWidth: true
            text: (root.notifModel && root.notifModel.notitext) ? root.notifModel.notitext : ""
            visible: text.length > 0
            font.family: "Google Sans Flex"
            font.pixelSize: 12
            color: Qt.rgba(1, 1, 1, 0.85)
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }

        // 4. Quick Reply Button / Input
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.isReplying ? 38 : 28
            visible: Boolean(root.notifModel && root.notifModel.repliable)

            RowLayout {
                anchors.fill: parent
                visible: !root.isReplying
                spacing: 8

                Rectangle {
                    Layout.preferredHeight: 26
                    Layout.preferredWidth: replyLabel.implicitWidth + 24
                    radius: 13
                    color: replyBtnMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.10)
                    border.color: Qt.rgba(1, 1, 1, 0.12)
                    border.width: 1

                    Text {
                        id: replyLabel
                        anchors.centerIn: parent
                        text: root.i18n("Reply")
                        font.family: "Google Sans Flex"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: "#FFFFFF"
                    }

                    MouseArea {
                        id: replyBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.isReplying = true;
                            replyInput.forceActiveFocus();
                        }
                    }
                }
            }

            // Inline reply input field
            RowLayout {
                anchors.fill: parent
                visible: root.isReplying
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 12
                    color: Qt.rgba(0, 0, 0, 0.30)
                    border.color: Qt.rgba(1, 1, 1, 0.20)
                    border.width: 1

                    TextInput {
                        id: replyInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: "Google Sans Flex"
                        font.pixelSize: 12
                        color: "#FFFFFF"
                        onAccepted: sendBtn.send()
                    }
                }

                Rectangle {
                    id: sendBtn
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 12
                    color: sendMa.containsMouse ? Kirigami.Theme.highlightColor : Qt.rgba(1, 1, 1, 0.15)

                    function send() {
                        var msg = replyInput.text.trim();
                        if (msg && root.notifModel) {
                            if (root.notifModel.dbusInterface && typeof root.notifModel.dbusInterface.sendReply === "function") {
                                root.notifModel.dbusInterface.sendReply(msg);
                            } else if (typeof root.notifModel.reply === "function") {
                                root.notifModel.reply(msg);
                            }
                            replyInput.text = "";
                            root.isReplying = false;
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "➔"
                        font.pixelSize: 13
                        color: "#FFFFFF"
                    }

                    MouseArea {
                        id: sendMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sendBtn.send()
                    }
                }
            }
        }
    }
}

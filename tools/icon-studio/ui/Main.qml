/*
 * SPDX-FileCopyrightText: 2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ApplicationWindow {
    id: root
    width: 700
    height: 560
    minimumWidth: 560
    minimumHeight: 420
    visible: true
    title: "Icon Studio"

    color: Kirigami.Theme.backgroundColor

    // --- State Properties ---
    property string searchQuery: ""
    property string selectedCategory: "All"
    property var categories: ["All", "Modified", "Google / Web", "System", "Launcher"]

    // --- Filter & Count Logic ---
    readonly property var allApps: backend ? backend.apps : []
    readonly property int modifiedCount: {
        var count = 0;
        for (var i = 0; i < allApps.length; ++i) {
            if (allApps[i].isModified) count++;
        }
        return count;
    }

    readonly property var filteredApps: {
        var res = [];
        var q = searchQuery.trim().toLowerCase();
        for (var i = 0; i < allApps.length; ++i) {
            var item = allApps[i];

            // 1. Category Filter
            if (selectedCategory === "Modified") {
                if (!item.isModified) continue;
            } else if (selectedCategory === "Launcher") {
                if (!item.isLauncher) continue;
            } else if (selectedCategory !== "All") {
                if (item.category !== selectedCategory) continue;
            }

            // 2. Search Query Filter
            if (q.length > 0) {
                var nameMatch = (item.name || "").toLowerCase().indexOf(q) !== -1;
                var idMatch = (item.id || "").toLowerCase().indexOf(q) !== -1;
                var commentMatch = (item.comment || "").toLowerCase().indexOf(q) !== -1;
                if (!nameMatch && !idMatch && !commentMatch) continue;
            }

            res.push(item);
        }
        return res;
    }

    // --- Main Layout ---
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // 1. Header (Search & Reload Plasma)
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Search Box
            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 22
                color: Kirigami.Theme.colorSet === Kirigami.Theme.View ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06) : Qt.rgba(1, 1, 1, 0.08)
                border.color: searchInput.activeFocus ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 12
                    spacing: 8

                    Kirigami.Icon {
                        source: "search"
                        width: 18
                        height: 18
                        color: Kirigami.Theme.disabledTextColor
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        color: Kirigami.Theme.textColor
                        clip: true
                        verticalAlignment: TextInput.AlignVCenter
                        onTextChanged: root.searchQuery = text

                        Text {
                            anchors.fill: parent
                            text: "Search applications or controls..."
                            font.pixelSize: 14
                            color: Kirigami.Theme.disabledTextColor
                            visible: !searchInput.text && !searchInput.activeFocus
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Item {
                        width: 24
                        height: 24
                        visible: searchInput.text.length > 0

                        Rectangle {
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            radius: 10
                            color: clearMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15) : "transparent"

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                source: "edit-clear"
                                width: 14
                                height: 14
                                color: Kirigami.Theme.disabledTextColor
                            }

                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchInput.text = ""
                            }
                        }
                    }
                }
            }

            // Reload Plasma Button
            Rectangle {
                height: 44
                radius: 22
                implicitWidth: reloadRow.implicitWidth + 28
                color: reloadMouse.containsMouse ? Qt.darker(Kirigami.Theme.highlightColor, 1.1) : Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.12)
                border.color: Kirigami.Theme.highlightColor
                border.width: 1

                RowLayout {
                    id: reloadRow
                    anchors.centerIn: parent
                    spacing: 8

                    Kirigami.Icon {
                        source: "view-refresh"
                        width: 16
                        height: 16
                        color: reloadMouse.containsMouse ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.highlightColor
                    }

                    Text {
                        text: "Reload Plasma"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: reloadMouse.containsMouse ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.highlightColor
                    }
                }

                ToolTip.visible: reloadMouse.containsMouse
                ToolTip.text: "Restart Plasma shell to refresh all desktop and launcher caches"

                MouseArea {
                    id: reloadMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backend.reloadPlasma()
                }
            }
        }

        // 2. Filter Bar (Chips)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: root.categories

                Rectangle {
                    required property string modelData
                    readonly property bool isSelected: root.selectedCategory === modelData
                    height: 32
                    radius: 16
                    color: isSelected ? Kirigami.Theme.highlightColor : (chipMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08) : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04))
                    border.color: isSelected ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                    border.width: 1

                    implicitWidth: chipRow.implicitWidth + 24

                    RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: {
                                if (modelData === "Modified") {
                                    return modelData + " (" + root.modifiedCount + ")";
                                }
                                return modelData;
                            }
                            font.pixelSize: 12
                            font.weight: isSelected ? Font.Medium : Font.Normal
                            color: isSelected ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                        }
                    }

                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedCategory = modelData
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        // 3. Applications List
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 16
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.02)
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
            border.width: 1
            clip: true

            ListView {
                id: appsListView
                anchors.fill: parent
                anchors.margins: 8
                model: root.filteredApps
                spacing: 8
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                }

                delegate: Rectangle {
                    id: rowCard
                    required property var modelData
                    width: appsListView.width
                    height: 64
                    radius: 12
                    color: dropArea.containsDrag ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15) : (cardHover.hovered ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.02))
                    border.color: dropArea.containsDrag ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)
                    border.width: dropArea.containsDrag ? 2 : 1

                    HoverHandler {
                        id: cardHover
                    }

                    // Drag & Drop Area
                    DropArea {
                        id: dropArea
                        anchors.fill: parent
                        onEntered: drag => {
                            if (drag.hasUrls) {
                                drag.acceptProposedAction();
                            }
                        }
                        onDropped: drop => {
                            if (drop.hasUrls && drop.urls.length > 0) {
                                var url = drop.urls[0].toString();
                                backend.setAppIcon(rowCard.modelData.id, url);
                                drop.acceptProposedAction();
                            }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 14

                        // App / Launcher Icon Preview
                        Rectangle {
                            width: 44
                            height: 44
                            radius: 10
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 32
                                height: 32
                                source: rowCard.modelData.icon
                                isMask: rowCard.modelData.isLauncher
                                color: Kirigami.Theme.textColor
                            }
                        }

                        // App Info
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                spacing: 8
                                Text {
                                    text: rowCard.modelData.name
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: Kirigami.Theme.textColor
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 320
                                }

                                Rectangle {
                                    visible: rowCard.modelData.isModified
                                    height: 18
                                    implicitWidth: modText.implicitWidth + 10
                                    radius: 9
                                    color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)
                                    border.color: Kirigami.Theme.highlightColor
                                    border.width: 1

                                    Text {
                                        id: modText
                                        anchors.centerIn: parent
                                        text: "Modified"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: Kirigami.Theme.highlightColor
                                    }
                                }
                            }

                            Text {
                                text: rowCard.modelData.isLauncher ? "Bottom shelf menu button icon" : (rowCard.modelData.comment ? (rowCard.modelData.comment + " • " + rowCard.modelData.id) : rowCard.modelData.id)
                                font.pixelSize: 12
                                color: Kirigami.Theme.disabledTextColor
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Actions
                        RowLayout {
                            spacing: 8

                            // Reset button (visible only if modified)
                            Rectangle {
                                visible: rowCard.modelData.isModified
                                width: 36
                                height: 36
                                radius: 18
                                color: resetMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1) : "transparent"
                                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                                border.width: 1

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    source: "edit-undo"
                                    width: 16
                                    height: 16
                                    color: Kirigami.Theme.textColor
                                }

                                ToolTip.visible: resetMouse.containsMouse
                                ToolTip.text: "Restore default icon"

                                MouseArea {
                                    id: resetMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.resetAppIcon(rowCard.modelData.id)
                                }
                            }

                            // Change Icon Button
                            Rectangle {
                                width: 100
                                height: 36
                                radius: 18
                                color: changeMouse.containsMouse ? Qt.darker(Kirigami.Theme.highlightColor, 1.1) : Kirigami.Theme.highlightColor

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Kirigami.Icon {
                                        source: "document-open"
                                        width: 14
                                        height: 14
                                        color: Kirigami.Theme.highlightedTextColor
                                    }

                                    Text {
                                        text: "Change"
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        color: Kirigami.Theme.highlightedTextColor
                                    }
                                }

                                MouseArea {
                                    id: changeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        backend.pickIconForApp(rowCard.modelData.id);
                                    }
                                }
                            }
                        }
                    }
                }

                // Empty State
                Text {
                    anchors.centerIn: parent
                    visible: root.filteredApps.length === 0
                    text: "No applications found matching search criteria."
                    font.pixelSize: 14
                    color: Kirigami.Theme.disabledTextColor
                }
            }
        }

        // 4. Subtle Hint Footer
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Kirigami.Icon {
                source: "dialog-information"
                width: 16
                height: 16
                color: Kirigami.Theme.disabledTextColor
            }

            Text {
                Layout.fillWidth: true
                text: "Tip: You can drag and drop SVG or PNG files directly onto any application card."
                font.pixelSize: 12
                color: Kirigami.Theme.disabledTextColor
            }
        }
    }

    // --- Status Popup (Toast) ---
    Rectangle {
        id: toast
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        anchors.horizontalCenter: parent.horizontalCenter
        height: 36
        implicitWidth: toastText.implicitWidth + 32
        radius: 18
        color: toast.isSuccess ? Qt.rgba(0.1, 0.7, 0.3, 0.95) : Qt.rgba(0.85, 0.2, 0.2, 0.95)
        visible: false
        opacity: 0.0

        property bool isSuccess: true

        Text {
            id: toastText
            anchors.centerIn: parent
            text: ""
            font.pixelSize: 12
            font.weight: Font.Medium
            color: "white"
        }

        NumberAnimation on opacity {
            id: toastFade
            duration: 250
        }

        Timer {
            id: toastTimer
            interval: 2500
            onTriggered: {
                toastFade.to = 0.0;
                toastFade.start();
            }
        }
    }

    Connections {
        target: backend
        function onStatusMessage(msg, is_success) {
            toastText.text = msg;
            toast.isSuccess = is_success;
            toast.visible = true;
            toastFade.to = 1.0;
            toastFade.start();
            toastTimer.restart();
        }
    }
}

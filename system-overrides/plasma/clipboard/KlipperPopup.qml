/*
    SPDX-FileCopyrightText: 2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects

import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.private.clipboard as Private
import org.kde.kirigami as Kirigami

PlasmaExtras.Representation {
    id: dialogItem

    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1.0
    function snap(val: real): real {
        return Math.round(val * dpr) / dpr;
    }

    readonly property real baseWidth: snap(360.0)
    readonly property real baseHeight: snap(420.0)

    implicitWidth: baseWidth
    implicitHeight: baseHeight
    width: baseWidth
    height: baseHeight

    signal requestHidePopup()

    focus: true
    collapseMarginsHint: true

    Keys.onEscapePressed: requestHidePopup()

    function updateContentSize(screenSize: size): void {
        dialogItem.implicitWidth = dialogItem.baseWidth;
        dialogItem.implicitHeight = dialogItem.baseHeight;
    }

    // Material You Theme tokens
    readonly property bool isDarkTheme: (Kirigami.Theme.backgroundColor.r * 0.299 + Kirigami.Theme.backgroundColor.g * 0.587 + Kirigami.Theme.backgroundColor.b * 0.114) < 0.5
    readonly property color cardBg: isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
    readonly property color cardHoverBg: isDarkTheme ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10)
    readonly property color cardBorder: isDarkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.09)
    readonly property color textPrimary: isDarkTheme ? "#f2f2f6" : "#1c1c22"
    readonly property color textSecondary: isDarkTheme ? "#9e9ea7" : "#5e5e68"
    readonly property color accentColor: Kirigami.Theme.highlightColor

    property bool isEditMode: false

    Private.HistoryModel {
        id: historyModel
    }

    // Dynamic Masonry Card Component
    Component {
        id: cardComponent

        Rectangle {
            id: card
            width: columnsRow.colWidth

            readonly property var cardLoader: parent as Loader
            readonly property string itemDisplay: cardLoader && cardLoader.itemModel && cardLoader.itemModel.display !== undefined ? String(cardLoader.itemModel.display) : ""
            readonly property var itemDecoration: cardLoader ? cardLoader.itemDecoration : null
            readonly property var itemUuid: cardLoader ? cardLoader.itemUuid : null
            readonly property int itemType: cardLoader ? cardLoader.itemType : 0
            readonly property bool isImage: itemType === 4 || (itemDecoration !== undefined && itemDecoration !== null && itemDecoration !== "" && itemType !== 2 && itemType !== 8)

            height: {
                if (isImage) {
                    if (imgPreview.sourceSize.width > 0 && imgPreview.sourceSize.height > 0) {
                        var aspectH = (width * imgPreview.sourceSize.height) / imgPreview.sourceSize.width;
                        return Math.max(dialogItem.snap(80.0), Math.min(dialogItem.snap(160.0), aspectH));
                    }
                    return dialogItem.snap(140.0);
                }
                var textH = txtPreview.implicitHeight;
                return Math.max(dialogItem.snap(38.0), Math.min(dialogItem.snap(110.0), textH + dialogItem.snap(20.0)));
            }

            radius: dialogItem.snap(12.0)
            color: delMouse.containsMouse ? dialogItem.cardHoverBg : dialogItem.cardBg
            border.color: dialogItem.cardBorder
            border.width: 1
            clip: true

            // Image representation with true rounded mask
            Image {
                id: imgPreview
                visible: card.isImage
                anchors.fill: parent
                source: card.itemDecoration ? card.itemDecoration : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
                layer.enabled: card.isImage
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: imgMask
                }
            }

            Rectangle {
                id: imgMask
                width: card.width
                height: card.height
                radius: card.radius
                visible: false
                layer.enabled: true
            }

            // Subtle border overlay on top of image
            Rectangle {
                visible: card.isImage
                anchors.fill: parent
                radius: card.radius
                color: "transparent"
                border.color: dialogItem.cardBorder
                border.width: 1
                z: 1
            }

            // Text representation
            Text {
                id: txtPreview
                visible: !card.isImage
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: dialogItem.snap(10.0)
                text: card.itemDisplay
                color: dialogItem.textPrimary
                font.pixelSize: Math.round(11.5 * dialogItem.dpr) / dialogItem.dpr
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 5
            }

            // Delete button in Edit mode
            Rectangle {
                visible: dialogItem.isEditMode
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: dialogItem.snap(4.0)
                width: dialogItem.snap(20.0)
                height: dialogItem.snap(20.0)
                radius: width / 2
                color: "#ff4d4d"
                z: 2

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    source: "edit-delete-symbolic"
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        historyModel.remove(card.itemUuid);
                    }
                }
            }

            MouseArea {
                id: delMouse
                anchors.fill: parent
                hoverEnabled: !dialogItem.isEditMode
                cursorShape: dialogItem.isEditMode ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: {
                    if (!dialogItem.isEditMode) {
                        historyModel.moveToTop(card.itemUuid);
                        dialogItem.requestHidePopup();
                    }
                }
                onWheel: wheel => {
                    wheel.accepted = false;
                }
            }
        }
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: dialogItem.snap(12.0)
        anchors.bottomMargin: dialogItem.snap(2.0)
        anchors.leftMargin: dialogItem.snap(12.0)
        anchors.rightMargin: dialogItem.snap(12.0)
        spacing: dialogItem.snap(6.0)

        // 1. Header: Title and Close button
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: dialogItem.snap(28.0)
            spacing: dialogItem.snap(6.0)

            Text {
                text: i18nd("klipper", "Clipboard")
                color: dialogItem.textPrimary
                font.bold: true
                font.pixelSize: Math.round(16 * dialogItem.dpr) / dialogItem.dpr
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
            }

            // Close Button
            Rectangle {
                Layout.preferredWidth: dialogItem.snap(30.0)
                Layout.preferredHeight: dialogItem.snap(30.0)
                radius: width / 2
                color: closeMouse.containsMouse ? (dialogItem.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: dialogItem.snap(21.0)
                    height: dialogItem.snap(21.0)
                    source: Qt.resolvedUrl("icons/close.svg")
                    color: dialogItem.textPrimary
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        dialogItem.requestHidePopup();
                    }
                }
            }
        }

        // 2. Section: Recent header + Edit mode toggle & Clear all buttons on the right
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: dialogItem.snap(2.0)
            Layout.preferredHeight: dialogItem.snap(26.0)
            spacing: dialogItem.snap(6.0)

            Text {
                text: i18n("Recent")
                color: dialogItem.textSecondary
                font.weight: Font.DemiBold
                font.pixelSize: Math.round(13 * dialogItem.dpr) / dialogItem.dpr
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
            }

            // Clear all button (only visible in edit mode)
            Rectangle {
                visible: dialogItem.isEditMode && historyModel.count > 0
                Layout.preferredWidth: dialogItem.snap(28.0)
                Layout.preferredHeight: dialogItem.snap(28.0)
                radius: dialogItem.snap(6.0)
                color: clearMouse.containsMouse ? Qt.rgba(1.0, 0.3, 0.3, 0.25) : "transparent"
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: dialogItem.snap(18.0)
                    height: dialogItem.snap(18.0)
                    source: "edit-delete-all-symbolic"
                    color: "#ff4d4d"
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        historyModel.clearHistory();
                        dialogItem.isEditMode = false;
                    }
                }
            }

            // Edit mode toggle icon (in line with Recent on the right)
            Rectangle {
                Layout.preferredWidth: dialogItem.snap(28.0)
                Layout.preferredHeight: dialogItem.snap(28.0)
                radius: dialogItem.snap(6.0)
                color: dialogItem.isEditMode ? dialogItem.accentColor : (editMouse.containsMouse ? (dialogItem.isDarkTheme ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent")
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: dialogItem.snap(21.0)
                    height: dialogItem.snap(21.0)
                    source: dialogItem.isEditMode ? "dialog-ok-apply-symbolic" : Qt.resolvedUrl("icons/edit.svg")
                    color: dialogItem.isEditMode ? (dialogItem.isDarkTheme ? "#1c1c22" : "white") : dialogItem.textPrimary
                }

                MouseArea {
                    id: editMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        dialogItem.isEditMode = !dialogItem.isEditMode;
                    }
                }
            }
        }

        // 3. Dynamic Masonry Grid of recent clipboard items
        Item {
            id: gridContainer
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                visible: historyModel.count === 0
                spacing: 8

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: dialogItem.snap(32.0)
                    Layout.preferredHeight: dialogItem.snap(32.0)
                    source: "edit-paste-symbolic"
                    color: dialogItem.textSecondary
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: i18n("Clipboard is empty")
                    color: dialogItem.textSecondary
                    font.pixelSize: Math.round(12 * dialogItem.dpr) / dialogItem.dpr
                }
            }

            Item {
                id: maskedFlickableArea
                anchors.fill: parent
                visible: historyModel.count > 0
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: bottomFadeMask
                }

                Flickable {
                    id: flickable
                    anchors.fill: parent
                    clip: false
                    contentWidth: width
                    contentHeight: columnsRow.height + dialogItem.snap(12.0)
                    boundsBehavior: Flickable.StopAtBounds

                    Kirigami.WheelHandler {
                        target: flickable
                        filterMouseEvents: true
                        keyNavigationEnabled: true
                        onWheel: wheel => {
                            var delta = wheel.angleDelta.y;
                            if (delta !== 0) {
                                flickable.flick(0, delta * 5);
                            }
                        }
                    }

                    Row {
                        id: columnsRow
                        width: flickable.width
                        spacing: dialogItem.snap(4.0)

                        readonly property real colWidth: Math.floor((width - spacing) / 2)

                        // Left Column (even items: 0, 2, 4...)
                        Column {
                            id: leftCol
                            width: columnsRow.colWidth
                            spacing: dialogItem.snap(4.0)

                            Repeater {
                                model: historyModel

                                delegate: Loader {
                                    id: leftLoader
                                    required property var model
                                    required property int index
                                    required property var decoration
                                    required property var uuid
                                    required property int type

                                    readonly property bool belongsHere: (index % 2 === 0)
                                    visible: belongsHere
                                    width: columnsRow.colWidth

                                    property var itemModel: leftLoader.model
                                    property var itemDecoration: leftLoader.decoration
                                    property var itemUuid: leftLoader.uuid
                                    property int itemType: leftLoader.type

                                    sourceComponent: belongsHere ? cardComponent : null
                                }
                            }
                        }

                        // Right Column (odd items: 1, 3, 5...)
                        Column {
                            id: rightCol
                            width: columnsRow.colWidth
                            spacing: dialogItem.snap(4.0)

                            Repeater {
                                model: historyModel

                                delegate: Loader {
                                    id: rightLoader
                                    required property var model
                                    required property int index
                                    required property var decoration
                                    required property var uuid
                                    required property int type

                                    readonly property bool belongsHere: (index % 2 === 1)
                                    visible: belongsHere
                                    width: columnsRow.colWidth

                                    property var itemModel: rightLoader.model
                                    property var itemDecoration: rightLoader.decoration
                                    property var itemUuid: rightLoader.uuid
                                    property int itemType: rightLoader.type

                                    sourceComponent: belongsHere ? cardComponent : null
                                }
                            }
                        }
                    }
                }
            }

            // Alpha gradient mask for seamless bottom fade
            Rectangle {
                id: bottomFadeMask
                anchors.fill: parent
                visible: false
                layer.enabled: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#ffffffff" }
                    GradientStop { position: Math.max(0.0, 1.0 - (dialogItem.snap(36.0) / Math.max(1.0, bottomFadeMask.height))); color: "#ffffffff" }
                    GradientStop { position: 1.0; color: "#00ffffff" }
                }
            }
        }
    }
}

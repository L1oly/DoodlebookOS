pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "i18n.js" as I18n

ColumnLayout {
    id: gridViewRoot
    anchors.fill: parent
    anchors.topMargin: 20
    anchors.bottomMargin: 14
    anchors.leftMargin: 16
    anchors.rightMargin: 16
    spacing: 6

    required property var rootApplet
    required property var popupContainer

    function commitTitle() {
        if (gridViewRoot.rootApplet.editingTitle) {
            gridViewRoot.rootApplet.saveTitle(titleEditor.text);
        }
    }

    Flickable {
        id: gridFlick
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: width
        contentHeight: appGrid.implicitHeight
        clip: true

        Grid {
            id: appGrid
            width: gridFlick.width
            columns: gridViewRoot.popupContainer.cols
            readonly property real cellW: Math.floor(width / columns)
            readonly property real cellH: 88

            Repeater {
                model: gridViewRoot.rootApplet.appList

                Item {
                    id: appTile
                    required property var modelData
                    required property int index

                    width: appGrid.cellW
                    height: appGrid.cellH

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 48
                            height: 48
                            scale: tileMouse.containsMouse && !tileMouse.pressed ? 1.05 : (tileMouse.pressed ? 0.94 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 48
                                height: 48
                                source: (appTile.modelData && appTile.modelData.icon) || "application-x-executable"
                                smooth: true
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: appTile.width - 8
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: appTile.modelData ? appTile.modelData.name : ""
                            font.family: "Google Sans Flex"
                            font.pixelSize: 12
                            font.weight: Font.Normal
                            color: gridViewRoot.popupContainer.cText
                        }
                    }

                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        pressAndHoldInterval: 350
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                gridViewRoot.rootApplet.editMode = !gridViewRoot.rootApplet.editMode;
                            } else if (gridViewRoot.rootApplet.editingTitle) {
                                gridViewRoot.rootApplet.saveTitle(titleEditor.text);
                            } else if (!gridViewRoot.rootApplet.editMode) {
                                gridViewRoot.popupContainer.close();
                                gridViewRoot.rootApplet.launchApp(appTile.modelData);
                            }
                        }

                        onPressAndHold: {
                            gridViewRoot.rootApplet.editMode = !gridViewRoot.rootApplet.editMode;
                        }
                    }

                    // Remove Badge (✕) in Edit Mode (Long-press or Right-click)
                    Rectangle {
                        visible: gridViewRoot.rootApplet.editMode
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 4
                        anchors.rightMargin: 14
                        width: 20
                        height: 20
                        radius: 10
                        color: "#EA4335"
                        z: 10

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 10
                            font.bold: true
                            color: "#FFFFFF"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                gridViewRoot.rootApplet.removeAppAt(appTile.index);
                            }
                        }
                    }
                }
            }
        }

        // Empty Folder Placeholder
        Item {
            anchors.fill: parent
            visible: gridViewRoot.rootApplet.appList.length === 0

            Column {
                anchors.centerIn: parent
                spacing: 8

                Kirigami.Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 36
                    height: 36
                    source: "folder-new"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: I18n.t("Folder is empty")
                    font.family: "Google Sans Flex"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: gridViewRoot.popupContainer.cSub
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 120
                    height: 30
                    radius: 15
                    color: emptyAddMouse.containsMouse ? gridViewRoot.popupContainer.cPillHover : gridViewRoot.popupContainer.cPill

                    Text {
                        anchors.centerIn: parent
                        text: I18n.t("Add apps")
                        font.family: "Google Sans Flex"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: gridViewRoot.popupContainer.cText
                    }

                    MouseArea {
                        id: emptyAddMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (gridViewRoot.rootApplet.allSystemApps.length === 0) gridViewRoot.rootApplet.fetchSystemApps();
                            gridViewRoot.rootApplet.addingMode = true;
                            gridViewRoot.rootApplet.editMode = false;
                        }
                    }
                }
            }
        }
    }

    // ====================================================
    // BOTTOM FOLDER TITLE (Click to Rename Inline)
    // ====================================================
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 32

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width, bottomTitleLabel.implicitWidth + 28)
            height: 28
            radius: 14
            color: bottomTitleMouse.containsMouse ? gridViewRoot.popupContainer.cPill : "transparent"
            visible: !gridViewRoot.rootApplet.editingTitle

            Text {
                id: bottomTitleLabel
                anchors.centerIn: parent
                text: gridViewRoot.rootApplet.folderName
                font.family: "Google Sans Flex"
                font.pixelSize: 15
                font.weight: Font.Normal
                color: gridViewRoot.popupContainer.cText
                elide: Text.ElideRight
            }

            MouseArea {
                id: bottomTitleMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.IBeamCursor
                onClicked: {
                    titleEditor.text = gridViewRoot.rootApplet.folderName;
                    gridViewRoot.rootApplet.editingTitle = true;
                    titleEditor.forceActiveFocus();
                    titleEditor.selectAll();
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: gridViewRoot.popupContainer.cPill
            visible: gridViewRoot.rootApplet.editingTitle

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 6
                spacing: 4

                TextInput {
                    id: titleEditor
                    Layout.fillWidth: true
                    horizontalAlignment: TextInput.AlignHCenter
                    font.family: "Google Sans Flex"
                    font.pixelSize: 15
                    color: gridViewRoot.popupContainer.cText
                    selectionColor: gridViewRoot.popupContainer.cAccent
                    selectedTextColor: "#FFFFFF"
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    onAccepted: {
                        gridViewRoot.rootApplet.saveTitle(text);
                    }
                    Keys.onEscapePressed: {
                        gridViewRoot.rootApplet.editingTitle = false;
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    Layout.alignment: Qt.AlignVCenter
                    radius: 11
                    color: gridViewRoot.popupContainer.cAccent

                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        font.pixelSize: 11
                        font.bold: true
                        color: "#FFFFFF"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: gridViewRoot.rootApplet.saveTitle(titleEditor.text)
                    }
                }
            }
        }
    }
}

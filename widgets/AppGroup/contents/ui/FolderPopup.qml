pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.Popup {
    id: folderPopup
    parent: QQC2.Overlay.overlay ? QQC2.Overlay.overlay : (rootApplet.Window ? rootApplet.Window.contentItem : rootApplet)

    required property var rootApplet
    required property var folderDisc

    readonly property int cols: (!folderPopup.rootApplet.addingMode && folderPopup.rootApplet.appList.length <= 4) ? 2 : 3
    readonly property int rows: Math.max(1, Math.ceil(folderPopup.rootApplet.appList.length / folderPopup.cols))

    width: folderPopup.rootApplet.addingMode ? 290 : (folderPopup.cols === 2 ? 224 : 292)
    height: folderPopup.rootApplet.addingMode ? 350 : Math.min(370, Math.max(232, folderPopup.rows * 90 + 62))
    padding: 0
    margins: 0
    modal: false
    focus: true
    closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside

    // Plasma Theme Colors
    readonly property color themeBg: Kirigami.Theme.backgroundColor
    readonly property color cSurface: Qt.rgba(themeBg.r, themeBg.g, themeBg.b, 0.97)
    readonly property color cText: Kirigami.Theme.textColor
    readonly property color cSub: Qt.rgba(cText.r, cText.g, cText.b, 0.65)
    readonly property color cPill: Qt.rgba(cText.r, cText.g, cText.b, 0.09)
    readonly property color cPillHover: Qt.rgba(cText.r, cText.g, cText.b, 0.16)
    readonly property color cAccent: Kirigami.Theme.highlightColor

    function commitPendingTitle() {
        if (folderGridView.visible) {
            folderGridView.commitTitle();
        }
        folderPopup.rootApplet.editingTitle = false;
    }

    function togglePopup() {
        if (visible) {
            close();
            return;
        }
        folderPopup.rootApplet.editingTitle = false;
        folderPopup.rootApplet.editMode = false;
        folderPopup.rootApplet.addingMode = false;
        folderPopup.rootApplet.searchQuery = "";

        var ov = QQC2.Overlay.overlay;
        if (ov && folderPopup.folderDisc) {
            var pt = folderPopup.folderDisc.mapToItem(ov, 0, 0);
            var iconCenterX = pt.x + folderPopup.folderDisc.width / 2;
            var iconCenterY = pt.y + folderPopup.folderDisc.height / 2;
            var horizRatio = (iconCenterX > ov.width / 2) ? 0.72 : 0.28;
            var desiredX = Math.round(iconCenterX - folderPopup.width * horizRatio);
            var desiredY = Math.round(iconCenterY - folderPopup.height * 0.34);
            x = Math.max(16, Math.min(ov.width - folderPopup.width - 16, desiredX));
            y = Math.max(16, Math.min(ov.height - folderPopup.height - 16, desiredY));
        } else {
            x = Math.round((folderPopup.rootApplet.width - folderPopup.width) * 0.28);
            y = -Math.round(folderPopup.height * 0.34);
        }
        open();
    }

    onClosed: {
        folderPopup.rootApplet.editingTitle = false;
        folderPopup.rootApplet.editMode = false;
        folderPopup.rootApplet.addingMode = false;
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 140; easing.type: Easing.OutQuad }
            NumberAnimation { property: "scale"; from: 0.85; to: 1.0; duration: 160; easing.type: Easing.OutBack }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 110; easing.type: Easing.InQuad }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.88; duration: 110; easing.type: Easing.InQuad }
        }
    }

    background: Rectangle {
        radius: 28
        color: folderPopup.cSurface
        border.width: 0
    }

    contentItem: Item {
        id: contentBox
        clip: true

        HoverHandler {
            id: cardHover
        }

        // Click on empty background commits title or exits editMode
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (folderPopup.rootApplet.editingTitle) {
                    folderPopup.commitPendingTitle();
                } else if (folderPopup.rootApplet.editMode) {
                    folderPopup.rootApplet.editMode = false;
                }
            }
        }

        // Subtle top-right "+" button to add apps (appears on hover or in editMode)
        Rectangle {
            visible: !folderPopup.rootApplet.addingMode && (cardHover.hovered || folderPopup.rootApplet.editMode)
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 10
            anchors.rightMargin: 12
            width: 26
            height: 26
            radius: 13
            color: addCornerMouse.containsMouse ? folderPopup.cPillHover : folderPopup.cPill
            z: 30

            Text {
                anchors.centerIn: parent
                text: "+"
                font.pixelSize: 16
                font.bold: true
                color: folderPopup.cText
            }

            MouseArea {
                id: addCornerMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (folderPopup.rootApplet.allSystemApps.length === 0) {
                        folderPopup.rootApplet.fetchSystemApps();
                    }
                    folderPopup.rootApplet.addingMode = true;
                    folderPopup.rootApplet.editMode = false;
                }
            }
        }

        // View 1: Folder grid
        FolderGridView {
            id: folderGridView
            visible: !folderPopup.rootApplet.addingMode
            rootApplet: folderPopup.rootApplet
            popupContainer: folderPopup
        }

        // View 2: App picker
        AppPickerView {
            id: appPickerView
            visible: folderPopup.rootApplet.addingMode
            rootApplet: folderPopup.rootApplet
            popupContainer: folderPopup
        }
    }
}

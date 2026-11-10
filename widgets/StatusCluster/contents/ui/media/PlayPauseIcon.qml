import QtQuick
import QtQuick.Effects

Item {
    id: root

    property bool isPlaying: false
    property color color: "#18181c"
    property real iconSize: 16

    implicitWidth: iconSize
    implicitHeight: iconSize

    Image {
        id: iconImg
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        sourceSize: Qt.size(Math.max(32, Math.round(root.iconSize * 2)), Math.max(32, Math.round(root.iconSize * 2)))
        fillMode: Image.PreserveAspectFit
        source: root.isPlaying ? Qt.resolvedUrl("icons/pause.svg") : Qt.resolvedUrl("icons/play_arrow.svg")
        visible: false
    }

    MultiEffect {
        anchors.fill: iconImg
        source: iconImg
        colorization: 1.0
        colorizationColor: root.color
    }
}

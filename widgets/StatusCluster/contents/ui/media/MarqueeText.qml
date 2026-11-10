import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property alias text: label.text
    property alias font: label.font
    property alias color: label.color
    property alias horizontalAlignment: label.horizontalAlignment
    property alias verticalAlignment: label.verticalAlignment

    property bool scrollOnClickOnly: true
    property bool scrollOnHoverOnly: false
    property bool hovered: false

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    clip: true

    readonly property bool overflowing: label.implicitWidth > root.width && root.width > 0
    readonly property real textOffset: label.x

    Text {
        id: label

        anchors.verticalCenter: parent.verticalCenter
        x: 0
        textFormat: Text.PlainText
        width: implicitWidth
        elide: Text.ElideNone

        onTextChanged: {
            root.resetScroll();
        }

        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
    }

    onWidthChanged: {
        root.resetScroll();
    }

    onScrollOnClickOnlyChanged: {
        root.resetScroll();
    }

    onHoveredChanged: {
        if (root.scrollOnHoverOnly) {
            if (root.hovered) {
                returnAnim.stop();
            } else {
                if (label.x !== 0) {
                    returnAnim.restart();
                }
            }
        }
    }

    NumberAnimation {
        id: returnAnim
        target: label
        property: "x"
        to: 0
        duration: 220
        easing.type: Easing.OutQuad
        onFinished: {
            label.x = 0;
        }
    }

    function resetScroll(): void {
        marqueeAnim.stop();
        returnAnim.stop();
        label.x = 0;
        if (!root.scrollOnClickOnly && !root.scrollOnHoverOnly && root.overflowing) {
            marqueeAnim.restart();
        } else if (root.scrollOnHoverOnly && root.hovered && root.overflowing) {
            marqueeAnim.restart();
        }
    }

    SequentialAnimation {
        id: marqueeAnim
        running: (!root.scrollOnClickOnly && !root.scrollOnHoverOnly && root.overflowing) ||
                 (root.scrollOnHoverOnly && root.hovered && root.overflowing)
        loops: root.scrollOnClickOnly ? 1 : Animation.Infinite

        PauseAnimation {
            duration: 250
        }

        NumberAnimation {
            target: label
            property: "x"
            to: -(label.implicitWidth - root.width + Kirigami.Units.smallSpacing * 2)
            duration: Math.max(2400, (label.implicitWidth - root.width) * 44)
            easing.type: Easing.InOutQuad
        }

        PauseAnimation {
            duration: 2200
        }

        NumberAnimation {
            target: label
            property: "x"
            to: 0
            duration: Math.max(1800, (label.implicitWidth - root.width) * 32)
            easing.type: Easing.InOutQuad
        }

        PauseAnimation {
            duration: 1000
        }

        onFinished: {
            label.x = 0;
        }
    }
}

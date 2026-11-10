pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import "i18n.js" as I18n

Item {
    id: expandedRoot

    function i18n(k, a1, a2) { return I18n.t(k, a1, a2); }

    property var root: null

    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1.0
    function snap(val) {
        return Math.round(val * dpr) / dpr;
    }

    implicitWidth: snap(360.0)
    implicitHeight: snap(158.4)
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.minimumWidth: implicitWidth
    Layout.minimumHeight: implicitHeight
    Layout.maximumWidth: implicitWidth
    Layout.maximumHeight: implicitHeight
    width: implicitWidth
    height: implicitHeight

    // Corner radius constant
    readonly property real cornerRadius32: 24

    function removeNativePlasmaFrame() {
        const win = Window.window;
        if (!win) return;

        win.color = "transparent";

        if (win.contentItem && win.contentItem.children) {
            const kids = win.contentItem.children;
            for (let i = 0; i < kids.length; ++i) {
                const child = kids[i];
                if (child !== expandedRoot && !expandedRoot.isItemAncestor(child, expandedRoot)) {
                    child.visible = false;
                    child.opacity = 0;
                    child.width = 0;
                    child.height = 0;
                    if (child.hasOwnProperty("imagePath")) {
                        child.imagePath = "";
                    }
                    if (child.hasOwnProperty("prefix")) {
                        child.prefix = "";
                    }
                }
            }
        }
    }

    function isItemAncestor(parentCandidate, item) {
        let p = item;
        while (p) {
            if (p === parentCandidate) return true;
            p = p.parent;
        }
        return false;
    }

    Component.onCompleted: {
        expandedRoot.removeNativePlasmaFrame();
        Qt.callLater(expandedRoot.removeNativePlasmaFrame);
    }

    Window.onWindowChanged: {
        expandedRoot.removeNativePlasmaFrame();
        if (Window.window) {
            Window.window.visibleChanged.connect(expandedRoot.removeNativePlasmaFrame);
        }
    }

    onVisibleChanged: {
        if (visible) {
            expandedRoot.removeNativePlasmaFrame();
            Qt.callLater(expandedRoot.removeNativePlasmaFrame);
        }
    }

    // Outer card container with 32dp rounded corners and optional album art
    Item {
        id: card
        anchors.fill: parent
        anchors.topMargin: (Window.window && typeof Window.window["topPadding"] === "number") ? -Window.window["topPadding"] : 0
        anchors.bottomMargin: (Window.window && typeof Window.window["bottomPadding"] === "number") ? -Window.window["bottomPadding"] : 0
        anchors.leftMargin: (Window.window && typeof Window.window["leftPadding"] === "number") ? -Window.window["leftPadding"] : 0
        anchors.rightMargin: (Window.window && typeof Window.window["rightPadding"] === "number") ? -Window.window["rightPadding"] : 0

        readonly property color themeBg: Kirigami.Theme.backgroundColor
        readonly property bool isDark: (themeBg.r * 0.299 + themeBg.g * 0.587 + themeBg.b * 0.114) < 0.5
        readonly property color cardBgColor: isDark ? Qt.darker(themeBg, 1.25) : Qt.lighter(themeBg, 1.05)
        readonly property color contentTextColor: (expandedRoot.root && expandedRoot.root.hasRealArtwork || isDark) ? "#ffffff" : Kirigami.Theme.textColor
        readonly property color contentSubtextColor: (expandedRoot.root && expandedRoot.root.hasRealArtwork || isDark) ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.75)

        // Solid adaptive background (displayed when no cover art is available or while loading)
        Rectangle {
            id: cardBg
            anchors.fill: parent
            radius: expandedRoot.cornerRadius32
            color: card.cardBgColor
        }

        // Mask matching the exact card 32dp rounded shape
        Rectangle {
            id: cardMask
            anchors.fill: parent
            radius: expandedRoot.cornerRadius32
            color: "black"
            visible: false
            layer.enabled: true
        }

        // Cover art image + gradient tint overlay (masked to 32dp rounded corners)
        Item {
            id: imageLayer
            anchors.fill: parent
            visible: Boolean(expandedRoot.root && expandedRoot.root.hasRealArtwork && coverImage.status === Image.Ready && coverImage.source.toString().length > 0)
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: cardMask
            }

            Image {
                id: coverImage
                anchors.fill: parent
                source: (expandedRoot.root && expandedRoot.root.hasRealArtwork) ? expandedRoot.root.artUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0.08, 0.07, 0.12, 0.45) }
                    GradientStop { position: 0.5; color: Qt.rgba(0.08, 0.07, 0.12, 0.60) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.08, 0.07, 0.12, 0.78) }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: expandedRoot.snap(12.8)
            spacing: Kirigami.Units.smallSpacing * 1.5

            // Top Row: Application icon in top-left corner
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: expandedRoot.snap(18.4)

                Kirigami.Icon {
                    id: sourceIcon
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.preferredWidth: expandedRoot.snap(18.4)
                    Layout.preferredHeight: Layout.preferredWidth
                    source: expandedRoot.root ? expandedRoot.root.appIcon : ""
                    fallback: (expandedRoot.root && expandedRoot.root.isChromeFallbackArt) ? expandedRoot.root.artUrl : ""
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            // Middle Row: Track info (left) & Play/Pause Button (right)
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.mediumSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    // Track Title (Cleaned of unread count badges like "(341)")
                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: (expandedRoot.root && expandedRoot.root.hasMedia) ? expandedRoot.root.track : i18n("No media playing")
                        font.family: "Google Sans Flex"
                        font.pixelSize: expandedRoot.snap(10.4)
                        font.weight: Font.Normal
                        color: card.contentTextColor
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    // Artist / App identity
                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: (expandedRoot.root && expandedRoot.root.hasMedia)
                            ? (expandedRoot.root.artist.length > 0 ? expandedRoot.root.artist : expandedRoot.root.identity)
                            : i18n("Paused")
                        font.family: "Google Sans Flex"
                        font.pixelSize: expandedRoot.snap(10.4)
                        font.weight: Font.Normal
                        color: card.contentSubtextColor
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                // Large rounded Play/Pause button: 81x54px (64.8x43.2 dp) with 19px (15.2 dp) top & bottom margin
                Rectangle {
                    id: bigPlayButton
                    Layout.preferredWidth: expandedRoot.snap(64.8)
                    Layout.preferredHeight: expandedRoot.snap(43.2)
                    Layout.topMargin: expandedRoot.snap(15.2)
                    Layout.bottomMargin: expandedRoot.snap(15.2)
                    radius: (expandedRoot.root && expandedRoot.root.isPlaying) ? 16 : (height / 2)
                    color: "#ffffff"

                    Behavior on radius {
                        NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
                    }

                    scale: bigPlayTap.pressed ? 0.94 : (bigPlayHover.hovered ? 1.04 : 1.0)
                    Behavior on scale {
                        NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutQuad }
                    }

                    PlayPauseIcon {
                        anchors.centerIn: parent
                        isPlaying: Boolean(expandedRoot.root && expandedRoot.root.isPlaying)
                        iconSize: Math.round(parent.height * 0.44)
                        color: "#18181c"
                    }

                    HoverHandler {
                        id: bigPlayHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        id: bigPlayTap
                        onTapped: {
                            if (expandedRoot.root) expandedRoot.root.togglePlaying();
                        }
                    }

                    PlasmaComponents3.ToolTip {
                        visible: bigPlayHover.hovered
                        text: (expandedRoot.root && expandedRoot.root.isPlaying) ? i18n("Sleep") : i18n("Play")
                    }
                }
            }

            // Bottom Row: Centered Squiggly Progress Slider (394px = 315.2 dp)
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.6)

                SquigglySlider {
                    id: waveSlider
                    anchors.centerIn: parent
                    width: expandedRoot.snap(315.2)
                    height: parent.height

                    value: expandedRoot.root ? expandedRoot.root.position : 0
                    to: expandedRoot.root ? expandedRoot.root.length : 0
                    from: 0
                    isPlaying: Boolean(expandedRoot.root && expandedRoot.root.isPlaying)
                    canSeek: Boolean(expandedRoot.root && expandedRoot.root.canSeek)
                    playedColor: "#ffffff"
                    thumbColor: "#ffffff"
                    unplayedColor: Qt.rgba(1, 1, 1, 0.32)

                    onSeekRequested: (newPos) => {
                        if (expandedRoot.root) expandedRoot.root.seek(newPos);
                    }
                }
            }
        }
    }
}

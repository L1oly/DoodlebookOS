import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: root

    property double value: 0      // In microseconds
    property double from: 0       // In microseconds
    property double to: 0         // In microseconds
    property bool isPlaying: false
    property bool canSeek: true

    property color playedColor: Kirigami.Theme.highlightColor
    property color unplayedColor: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.28)
    property color thumbColor: Kirigami.Theme.highlightColor

    signal seekRequested(double position)

    implicitWidth: Kirigami.Units.gridUnit * 10
    implicitHeight: Math.max(32, Kirigami.Units.gridUnit * 1.6)

    readonly property bool isLive: to > from && to > 0
    property bool userSeeking: false
    property double userPosition: 0
    property real phase: 0

    property real waveAmplitude: root.isPlaying && !root.userSeeking ? 2.8 : 0.0

    Behavior on waveAmplitude {
        NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
    }

    readonly property double effectivePosition: userSeeking ? userPosition : value
    readonly property real progressFraction: isLive ? Math.max(0, Math.min(1.0, (effectivePosition - from) / (to - from))) : 0.0
    readonly property real progressX: Math.round(progressFraction * width)

    NumberAnimation on phase {
        from: 0
        to: Math.PI * 2
        duration: 3200
        loops: Animation.Infinite
        running: root.visible && root.isPlaying && !root.userSeeking
    }

    onProgressXChanged: canvas.requestPaint()
    onPhaseChanged: canvas.requestPaint()
    onWaveAmplitudeChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
    onPlayedColorChanged: canvas.requestPaint()
    onUnplayedColorChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);

            var centerY = Math.round(height / 2);
            var progX = root.progressX;
            var trackThickness = 3.5;

            // 1. Unplayed straight line (from progX to width)
            if (progX < width) {
                ctx.strokeStyle = root.unplayedColor;
                ctx.lineWidth = trackThickness;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.moveTo(Math.max(0, progX), centerY);
                ctx.lineTo(width, centerY);
                ctx.stroke();
            }

            // 2. Played squiggly waveform (from 0 to progX)
            if (progX > 2) {
                ctx.strokeStyle = root.playedColor;
                ctx.lineWidth = trackThickness;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.moveTo(0, centerY);

                var wavelength = 38; // Wave cycle length in pixels (rzadsze fale)
                var amplitude = root.waveAmplitude; // Animated: 2.8 when playing (odrobinę wyższe fale), 0.0 when paused
                var taperDistance = 14.0; // Distance over which amplitude tapers to 0

                var step = 1.5;
                for (var x = 0; x <= progX; x += step) {
                    var taperStart = Math.min(1.0, x / taperDistance);
                    var taperEnd = Math.min(1.0, (progX - x) / taperDistance);
                    var amp = amplitude * taperStart * taperEnd;

                    var y = centerY + Math.sin(((x / wavelength) * 2 * Math.PI) - root.phase) * amp;
                    ctx.lineTo(x, y);
                }
                ctx.lineTo(progX, centerY);
                ctx.stroke();
            }
        }
    }

    // Vertical capsule / pill playhead thumb
    Rectangle {
        id: thumb
        x: Math.round(root.progressX - width / 2)
        anchors.verticalCenter: parent.verticalCenter
        width: mouseArea.containsMouse || root.userSeeking ? 5 : 4
        height: mouseArea.containsMouse || root.userSeeking ? 20 : 16
        radius: width / 2
        color: root.thumbColor
        visible: root.isLive

        Behavior on width {
            NumberAnimation { duration: Kirigami.Units.shortDuration }
        }
        Behavior on height {
            NumberAnimation { duration: Kirigami.Units.shortDuration }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.canSeek && root.isLive
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        function updateSeek(mouse) {
            var frac = Math.max(0, Math.min(1.0, mouse.x / root.width));
            root.userPosition = root.from + frac * (root.to - root.from);
            canvas.requestPaint();
        }

        onPressed: (mouse) => {
            root.userSeeking = true;
            updateSeek(mouse);
            seekToolTip.visible = true;
        }

        onPositionChanged: (mouse) => {
            if (pressed) {
                updateSeek(mouse);
            }
        }

        onReleased: (mouse) => {
            if (root.userSeeking) {
                updateSeek(mouse);
                root.seekRequested(root.userPosition);
                root.userSeeking = false;
                seekToolTip.visible = false;
            }
        }

        QQC2.ToolTip {
            id: seekToolTip
            visible: mouseArea.containsMouse && root.isLive
            delay: root.userSeeking ? 0 : Kirigami.Units.toolTipDelay
            timeout: -1
            text: root.formatDuration(root.effectivePosition) + " / " + root.formatDuration(root.to)
        }
    }

    function formatDuration(microseconds: double): string {
        if (!microseconds || isNaN(microseconds) || microseconds < 0) {
            return "0:00";
        }
        var totalSec = Math.floor(microseconds / 1000000);
        var hours = Math.floor(totalSec / 3600);
        var minutes = Math.floor((totalSec % 3600) / 60);
        var seconds = totalSec % 60;
        var padSec = seconds < 10 ? "0" + seconds : seconds;

        if (hours > 0) {
            var padMin = minutes < 10 ? "0" + minutes : minutes;
            return hours + ":" + padMin + ":" + padSec;
        }
        return minutes + ":" + padSec;
    }
}

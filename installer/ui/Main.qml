/*
 * SPDX-FileCopyrightText: 2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: win
    width: 1040
    height: 680
    minimumWidth: 960
    minimumHeight: 640
    visible: true
    color: "#F4EFF4"
    title: isPl ? "Instalator DoodlebookOS" : "DoodlebookOS Setup"

    property bool isPl: false // English is the default; set to true to enable the bundled Polish translation
    property int stepIndex: 0 // 0: Welcome, 1: Automated Options, 2: Installing, 3: All Set + Guide
    property bool showLogs: false
    property bool installSucceeded: true
    property string restoreBannerText: ""

    // Alpha preset always installs the complete out-of-the-box configuration

    // DoodlebookOS OOBE Palette
    readonly property color cBg: "#F4EFF4"
    readonly property color cSurfaceCard: "#EAE3EE"
    readonly property color cSurfaceCardActive: "#E3DCEF"
    readonly property color cInk: "#1D1B20"
    readonly property color cSub: "#49454F"
    readonly property color cPill: "#4F5478"
    readonly property color cAccent: cPill
    readonly property color cPillHover: "#5B6088"
    readonly property color cPillPressed: "#414666"
    readonly property color cCircleBtn: "#E7E0EC"
    readonly property color cCircleHover: "#DDD4E4"
    readonly property color cClover: "#514E60"
    readonly property color cCloverIcon: "#EADDFF"
    readonly property color cOutline: "#B0A9B9"
    readonly property string fontMain: "Google Sans Flex"

    function recenterWindow() {
        if (Screen.width > 0 && Screen.height > 0) {
            var targetX = Screen.virtualX + Math.max(0, Math.round((Screen.width - win.width) / 2));
            var targetY = Screen.virtualY + Math.max(0, Math.round((Screen.height - win.height) / 2));
            win.x = targetX;
            win.y = targetY;
        }
    }

    Timer {
        id: recenterTimer
        interval: 250
        repeat: false
        onTriggered: win.recenterWindow()
    }

    Connections {
        target: Screen
        function onWidthChanged() { recenterTimer.restart(); }
        function onHeightChanged() { recenterTimer.restart(); }
        function onDevicePixelRatioChanged() { recenterTimer.restart(); }
    }

    Connections {
        target: backend
        function onInstallFinished(ok, msg) {
            win.installSucceeded = ok;
            win.stepIndex = 3;
            recenterTimer.restart();
        }
        function onRestoreFinished(ok, msg) {
            win.restoreBannerText = msg;
        }
        function onDisplayScaleChanged() {
            recenterTimer.restart();
        }
    }

    Component.onCompleted: {
        recenterTimer.restart();
    }

    // =========================================================================
    // Reusable DoodlebookOS OOBE Components
    // =========================================================================

    component CircleIconButton: Rectangle {
        id: cBtn
        property string symbol: "←"
        signal clicked()

        width: 38
        height: 38
        radius: 19
        color: cMouse.pressed ? "#D0C7D8" : (cMouse.containsMouse ? win.cCircleHover : win.cCircleBtn)
        Behavior on color { ColorAnimation { duration: 140 } }

        Text {
            anchors.centerIn: parent
            text: cBtn.symbol
            font.family: win.fontMain
            font.pixelSize: 16
            font.weight: Font.Medium
            color: win.cInk
        }

        MouseArea {
            id: cMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: cBtn.clicked()
        }
    }

    component OobePillButton: Rectangle {
        id: pBtn
        property string text: ""
        property bool outlined: false
        implicitWidth: 380
        implicitHeight: 46
        radius: height / 2
        color: {
            if (outlined) {
                return pMouse.pressed ? "#E7E0EC" : (pMouse.containsMouse ? "#EDE7F2" : "transparent");
            }
            return pMouse.pressed ? win.cPillPressed : (pMouse.containsMouse ? win.cPillHover : win.cPill);
        }
        border.width: outlined ? 1.5 : 0
        border.color: win.cOutline

        Behavior on color { ColorAnimation { duration: 140 } }
        scale: pMouse.pressed ? 0.985 : 1.0
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        signal clicked()

        Text {
            anchors.centerIn: parent
            text: pBtn.text
            font.family: win.fontMain
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: pBtn.outlined ? win.cInk : "#FFFFFF"
        }

        MouseArea {
            id: pMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: pBtn.clicked()
        }
    }

    // Guide / Info Card for OOBE Steps
    component OobeGuideCard: Rectangle {
        id: gCard
        property string badgeSymbol: "❖"
        property string titleText: ""
        property string bodyText: ""

        Layout.fillWidth: true
        implicitHeight: Math.max(88, guideCardRow.implicitHeight + 26)
        radius: 20
        color: win.cSurfaceCard
        border.width: 1
        border.color: "#D5CDD9"

        RowLayout {
            id: guideCardRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 16

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                width: 40
                height: 40
                radius: 20
                color: win.cClover

                Text {
                    anchors.centerIn: parent
                    text: gCard.badgeSymbol
                    font.family: win.fontMain
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: win.cCloverIcon
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: gCard.titleText
                    font.family: win.fontMain
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: win.cInk
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: gCard.bodyText
                    font.family: win.fontMain
                    font.pixelSize: 12
                    lineHeight: 1.3
                    color: win.cSub
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    component OobeSwitchCard: Rectangle {
        id: sCard
        property string badgeSymbol: "🌙"
        property string titleText: ""
        property string bodyText: ""
        property string cliText: ""
        property bool checked: false
        signal toggled(bool newState)

        implicitWidth: 380
        implicitHeight: Math.max(76, switchCardRow.implicitHeight + 20)
        radius: 20
        color: win.cSurfaceCard
        border.width: 1
        border.color: checked ? win.cAccent : "#D5CDD9"
        Behavior on border.color { ColorAnimation { duration: 180 } }

        RowLayout {
            id: switchCardRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                width: 36
                height: 36
                radius: 18
                color: sCard.checked ? win.cAccent : win.cClover
                Behavior on color { ColorAnimation { duration: 180 } }

                Text {
                    anchors.centerIn: parent
                    text: sCard.badgeSymbol
                    font.family: win.fontMain
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: sCard.checked ? "#FFFFFF" : win.cCloverIcon
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: sCard.titleText
                    font.family: win.fontMain
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: win.cInk
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: sCard.bodyText
                    font.family: win.fontMain
                    font.pixelSize: 11
                    color: win.cSub
                    wrapMode: Text.WordWrap
                }

                Text {
                    visible: sCard.cliText.length > 0
                    Layout.fillWidth: true
                    text: sCard.cliText
                    font.family: "Monospace"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: win.cInk
                    wrapMode: Text.WordWrap
                }
            }

            // M3 Switch Toggle
            Rectangle {
                id: switchTrack
                Layout.preferredWidth: 46
                Layout.preferredHeight: 26
                radius: 13
                color: sCard.checked ? win.cAccent : "#E2DDE6"
                border.width: sCard.checked ? 0 : 2
                border.color: "#8E8D99"
                Behavior on color { ColorAnimation { duration: 180 } }

                Rectangle {
                    id: switchThumb
                    width: sCard.checked ? 20 : 16
                    height: width
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    x: sCard.checked ? parent.width - width - 3 : 4
                    color: sCard.checked ? "#FFFFFF" : "#8E8D99"
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on width { NumberAnimation { duration: 180 } }
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        sCard.checked = !sCard.checked;
                        sCard.toggled(sCard.checked);
                    }
                }
            }
        }
    }

    // Material 3 Expressive 4-Lobed Clover / Scallop Shape
    component M3CloverBadge: Item {
        id: clover
        property string centerSymbol: "✦"
        property bool spinning: false
        property real rotAngle: 0
        width: 190
        height: 190

        NumberAnimation on rotAngle {
            from: 0
            to: 360
            duration: 18000
            loops: Animation.Infinite
            running: clover.spinning
        }

        Canvas {
            id: cloverCanvas
            anchors.fill: parent
            rotation: clover.rotAngle
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var cx = width / 2;
                var cy = height / 2;
                var baseR = width * 0.39;
                var amp = width * 0.068;

                ctx.beginPath();
                var steps = 180;
                for (var i = 0; i <= steps; i++) {
                    var theta = (i / steps) * Math.PI * 2;
                    var r = baseR - amp * Math.cos(4 * theta);
                    var x = cx + r * Math.cos(theta);
                    var y = cy + r * Math.sin(theta);
                    if (i === 0) ctx.moveTo(x, y);
                    else ctx.lineTo(x, y);
                }
                ctx.closePath();
                ctx.fillStyle = win.cClover;
                ctx.fill();
            }
        }

        Canvas {
            id: glyphCanvas
            anchors.centerIn: parent
            width: 80
            height: 80
            visible: clover.centerSymbol === "user_device"
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = win.cCloverIcon;

                ctx.beginPath();
                ctx.arc(width / 2, height * 0.32, 13, 0, Math.PI * 2);
                ctx.fill();

                ctx.beginPath();
                ctx.moveTo(width * 0.18, height * 0.78);
                ctx.quadraticCurveTo(width * 0.18, height * 0.54, width * 0.50, height * 0.54);
                ctx.quadraticCurveTo(width * 0.82, height * 0.54, width * 0.82, height * 0.78);
                ctx.quadraticCurveTo(width * 0.82, height * 0.84, width * 0.74, height * 0.84);
                ctx.lineTo(width * 0.26, height * 0.84);
                ctx.quadraticCurveTo(width * 0.18, height * 0.84, width * 0.18, height * 0.78);
                ctx.closePath();
                ctx.fill();
            }
        }

        Text {
            anchors.centerIn: parent
            visible: clover.centerSymbol !== "user_device"
            text: clover.centerSymbol
            font.family: win.fontMain
            font.pixelSize: 38
            font.weight: Font.Bold
            color: win.cCloverIcon
        }
    }

    // Expressive Squiggly Progress Wave
    component OobeSquigglyProgress: Item {
        id: sq
        property real progress: 0.0
        property bool active: true
        property real phase: 0.0
        implicitWidth: 380
        implicitHeight: 22

        NumberAnimation on phase {
            from: 0
            to: Math.PI * 2
            duration: 850
            loops: Animation.Infinite
            running: sq.active
        }

        onPhaseChanged: sqCanvas.requestPaint()
        onProgressChanged: sqCanvas.requestPaint()

        Canvas {
            id: sqCanvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var w = width;
                var h = height;
                var midY = h / 2;
                var progX = Math.max(10, Math.min(w - 4, w * sq.progress));
                var amp = sq.active ? 4.5 : 0.0;
                var freq = 0.15;

                ctx.beginPath();
                ctx.lineWidth = 4.5;
                ctx.lineCap = "round";
                ctx.strokeStyle = win.cPill;
                for (var x = 4; x <= progX; x += 2) {
                    var y = midY + Math.sin(x * freq - sq.phase) * amp;
                    if (x === 4) ctx.moveTo(x, y);
                    else ctx.lineTo(x, y);
                }
                ctx.stroke();

                if (progX < w - 12) {
                    ctx.beginPath();
                    ctx.lineWidth = 4.5;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = "#D8D0E0";
                    ctx.moveTo(progX + 10, midY);
                    ctx.lineTo(w - 4, midY);
                    ctx.stroke();
                }
            }
        }
    }

    // =========================================================================
    // MAIN CONTENT AREA (4 Clean OOBE Steps)
    // =========================================================================
    Item {
        anchors.fill: parent
        anchors.margins: 40

        // ---------------------------------------------------------------------
        // STEP 0: WELCOME ("Hi there")
        // ---------------------------------------------------------------------
        Item {
            anchors.fill: parent
            visible: win.stepIndex === 0
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 220 } }

            RowLayout {
                anchors.fill: parent
                spacing: 32

                // Left Illustration (DoodlebookOS OOBE Floating Sphere & Characters)
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Canvas {
                        id: heroIllustration
                        anchors.centerIn: parent
                        width: 400
                        height: 400
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();

                            function pill(x1, y1, x2, y2, thickness, color) {
                                ctx.beginPath();
                                ctx.lineWidth = thickness;
                                ctx.lineCap = "round";
                                ctx.strokeStyle = color;
                                ctx.moveTo(x1, y1);
                                ctx.lineTo(x2, y2);
                                ctx.stroke();
                            }

                            var cx = 200, cy = 210, r = 82;
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, 0, Math.PI * 2);
                            ctx.fillStyle = "#E2DDE6";
                            ctx.fill();

                            // Top-left floating character
                            pill(70, 118, 112, 112, 13, "#DFAA8B");
                            pill(150, 108, 178, 128, 12, "#DFAA8B");

                            ctx.beginPath();
                            ctx.moveTo(118, 72);
                            ctx.bezierCurveTo(148, 56, 188, 70, 184, 98);
                            ctx.bezierCurveTo(176, 114, 138, 104, 118, 72);
                            ctx.fillStyle = "#EE7752";
                            ctx.fill();

                            ctx.beginPath();
                            ctx.arc(124, 84, 13, 0, Math.PI * 2);
                            ctx.fillStyle = "#DFAA8B";
                            ctx.fill();

                            pill(64, 168, 78, 180, 16, "#3B4A74");
                            pill(128, 198, 144, 206, 16, "#3B4A74");

                            pill(76, 166, 112, 138, 32, "#DCE2F2");
                            pill(134, 188, 124, 146, 30, "#DCE2F2");

                            ctx.beginPath();
                            ctx.arc(130, 122, 28, 0, Math.PI * 2);
                            ctx.fillStyle = "#434257";
                            ctx.fill();

                            // Bottom-right floating character
                            pill(214, 240, 238, 274, 13, "#D99B6E");
                            pill(282, 294, 304, 314, 13, "#D99B6E");

                            ctx.beginPath();
                            ctx.arc(266, 258, 13, 0, Math.PI * 2);
                            ctx.fillStyle = "#D99B6E";
                            ctx.fill();
                            ctx.beginPath();
                            ctx.arc(270, 252, 12, -Math.PI * 0.8, Math.PI * 0.3);
                            ctx.fillStyle = "#8C5230";
                            ctx.fill();

                            pill(242, 276, 280, 304, 34, "#4C5986");

                            pill(194, 318, 232, 294, 28, "#E3E6F0");
                            pill(232, 294, 260, 324, 28, "#E3E6F0");

                            pill(168, 328, 190, 322, 15, "#8E8D99");
                            pill(246, 336, 232, 316, 15, "#5B5A66");

                            function drawStar(sx, sy, sr, points, col) {
                                ctx.save();
                                ctx.translate(sx, sy);
                                ctx.beginPath();
                                var total = points * 2;
                                for (var i = 0; i < total; i++) {
                                    var rad = (i % 2 === 0) ? sr : sr * 0.42;
                                    var ang = (i * Math.PI) / points;
                                    var px = Math.cos(ang) * rad;
                                    var py = Math.sin(ang) * rad;
                                    if (i === 0) ctx.moveTo(px, py);
                                    else ctx.lineTo(px, py);
                                }
                                ctx.closePath();
                                ctx.fillStyle = col;
                                ctx.fill();
                                ctx.restore();
                            }
                            drawStar(252, 146, 10, 8, "#DF9B28");
                            drawStar(258, 76, 4.5, 4, "#C5B8D8");
                            drawStar(154, 302, 5, 4, "#B5ACC8");

                            var dots = [
                                [236, 72, 2.5, "#4A4860"],
                                [282, 102, 3.2, "#4A4860"],
                                [224, 174, 2.5, "#4A4860"],
                                [134, 274, 2.5, "#B5ACC8"]
                            ];
                            for (var d = 0; d < dots.length; d++) {
                                ctx.beginPath();
                                ctx.arc(dots[d][0], dots[d][1], dots[d][2], 0, Math.PI * 2);
                                ctx.fillStyle = dots[d][3];
                                ctx.fill();
                            }
                        }
                    }

                    Image {
                        id: doodleLogo
                        anchors.horizontalCenter: heroIllustration.horizontalCenter
                        anchors.verticalCenter: heroIllustration.verticalCenter
                        anchors.verticalCenterOffset: 10
                        width: 96
                        height: 96
                        source: Qt.resolvedUrl("assets/DoodlebookOS_Logo.png")
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }
                }

                // Right Column (Greeting + Start Button)
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -16
                        spacing: 16

                        Text {
                            text: win.isPl ? "Cześć!" : "Hi there"
                            font.family: win.fontMain
                            font.pixelSize: 48
                            font.weight: Font.Normal
                            color: win.cInk
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: win.isPl
                                ? "Witaj w instalatorze DoodlebookOS dla KDE Plasma 6. Przekształcimy Twój pulpit w kompletne środowisko Material 3 Expressive — automatycznie i bez ręcznego grzebania w ustawieniach."
                                : "Welcome to the DoodlebookOS installer for KDE Plasma 6. We'll transform your desktop into a complete Material 3 Expressive experience—automatically and effortlessly."
                            font.family: win.fontMain
                            font.pixelSize: 15
                            lineHeight: 1.4
                            color: win.cSub
                        }

                        RowLayout {
                            visible: false // language switch hidden until more translations are available
                            spacing: 10
                            CircleIconButton {
                                symbol: "🌐"
                                onClicked: win.isPl = !win.isPl
                            }
                            Text {
                                text: win.isPl ? "Polski (kliknij, aby zmienić na EN)" : "English (click to switch to PL)"
                                font.family: win.fontMain
                                font.pixelSize: 12
                                color: win.cSub
                            }
                        }
                    }

                    // Bottom-right start pill button
                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        width: 230
                        height: 46
                        radius: 23
                        color: nextMouse.pressed ? win.cPillPressed : (nextMouse.containsMouse ? win.cPillHover : win.cPill)
                        Behavior on color { ColorAnimation { duration: 140 } }

                        Text {
                            anchors.centerIn: parent
                            text: win.isPl ? "Rozpocznij  →" : "Get started  →"
                            font.family: win.fontMain
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            color: "#FFFFFF"
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: win.stepIndex = 1
                        }
                    }
                }
            }
        }

        // ---------------------------------------------------------------------
        // STEP 1: EARLY PREVIEW (ALPHA) INFORMATION & BACKUP RESTORE
        // ---------------------------------------------------------------------
        Item {
            anchors.fill: parent
            visible: win.stepIndex === 1
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 220 } }

            // Top-left back button
            CircleIconButton {
                anchors.top: parent.top
                anchors.left: parent.left
                symbol: "←"
                onClicked: win.stepIndex = 0
            }

            // Left Column: Heading + Explanation + Clover Badge + Restore Banner
            ColumnLayout {
                anchors.top: parent.top
                anchors.topMargin: 50
                anchors.left: parent.left
                width: 390
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: win.isPl
                        ? "Wczesny podgląd\n(Wersja Alpha)"
                        : "Early Preview\n(Alpha Release)"
                    font.family: win.fontMain
                    font.pixelSize: 36
                    font.weight: Font.Normal
                    lineHeight: 1.12
                    color: win.cInk
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: win.isPl
                        ? "Dziękujemy za testowanie DoodlebookOS! Przed zainstalowaniem środowiska na Twoim koncie zapoznaj się z krótką informacją o tym wydaniu:"
                        : "Thank you for testing DoodlebookOS! Before applying the desktop preset to your account, please keep a few important things in mind:"
                    font.family: win.fontMain
                    font.pixelSize: 13
                    lineHeight: 1.38
                    color: win.cSub
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 185
                    M3CloverBadge {
                        anchors.centerIn: parent
                        width: 170
                        height: 170
                        centerSymbol: "user_device"
                    }
                }

                Text {
                    visible: win.restoreBannerText !== ""
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: win.restoreBannerText
                    font.family: win.fontMain
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: win.cPill
                }
            }

            // Bottom-left: Restore previous settings / Uninstall
            OobePillButton {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                implicitWidth: 350
                text: win.isPl
                    ? "Przywróć poprzedni pulpit z kopii"
                    : "Restore previous desktop backup"
                outlined: true
                onClicked: backend.restoreOrUninstall()
            }

            // Right Column: 3 Alpha Release Info Cards + Install Button
            ColumnLayout {
                anchors.top: parent.top
                anchors.topMargin: 50
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: Math.max(520, parent.width - 418)
                spacing: 14

                OobeGuideCard {
                    badgeSymbol: "!"
                    titleText: win.isPl
                        ? "Wersja testowa — nie wszystko może działać"
                        : "Experimental Alpha Build"
                    bodyText: win.isPl
                        ? "To wczesna wersja rozwojowa dla KDE Plasma 6. Część funkcji jest jeszcze nieukończona, a niektóre elementy mogą zawierać błędy lub nie działać na każdej konfiguracji."
                        : "This is an early development preview for KDE Plasma 6. Some features are still work in progress, and certain elements may have bugs or not work on every setup yet."
                }

                OobeGuideCard {
                    badgeSymbol: "+"
                    titleText: win.isPl
                        ? "Personalizacja instalacji i nowe funkcje wkrótce"
                        : "Custom Setup & More Features Coming Soon"
                    bodyText: win.isPl
                        ? "W wersji Alpha instalator wgrywa pełny domyślny zestaw automatycznie. Możliwość wyboru instalowanych składników, integracja Phone Hub oraz własne aplikacje ustawień pojawią się wkrótce."
                        : "In this Alpha build, the installer applies the complete default preset automatically. Custom component selection and dedicated settings apps are coming soon."
                }

                OobeGuideCard {
                    badgeSymbol: "↺"
                    titleText: win.isPl
                        ? "Automatyczna kopia zapasowa i szybki powrót"
                        : "Automatic Backup & Easy Restore"
                    bodyText: win.isPl
                        ? "Przed wprowadzeniem zmian instalator zapisuje kopię Twoich obecnych ustawień KDE. W każdej chwili możesz przywrócić poprzedni pulpit przyciskiem po lewej stronie."
                        : "Your current KDE configuration is backed up automatically before any changes are made. You can revert to your previous desktop anytime using the button on the left."
                }

                Item { Layout.fillHeight: true }

                OobePillButton {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: 520
                    text: win.isPl
                        ? "Zainstaluj DoodlebookOS (Alpha)"
                        : "Install DoodlebookOS (Alpha)"
                    outlined: false
                    onClicked: {
                        win.stepIndex = 2;
                        backend.startSetup(
                            true,
                            true,
                            true,
                            true,
                            true,
                            "scheme",
                            "#4285F4",
                            win.isPl
                        );
                    }
                }
            }
        }

        // ---------------------------------------------------------------------
        // STEP 2: INSTALLING IN PROGRESS
        // ---------------------------------------------------------------------
        Item {
            anchors.fill: parent
            visible: win.stepIndex === 2
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 220 } }

            ColumnLayout {
                anchors.top: parent.top
                anchors.topMargin: 58
                anchors.left: parent.left
                width: 420
                spacing: 18

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: win.isPl
                        ? "Konfigurowanie\nTwojego pulpitu…"
                        : "Setting up\nyour desktop…"
                    font.family: win.fontMain
                    font.pixelSize: 40
                    font.weight: Font.Normal
                    lineHeight: 1.12
                    color: win.cInk
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: backend ? (win.isPl ? backend.statusPl : backend.statusEn) : ""
                    font.family: win.fontMain
                    font.pixelSize: 15
                    color: win.cSub
                }

                Rectangle {
                    visible: win.showLogs
                    Layout.fillWidth: true
                    Layout.preferredHeight: 210
                    radius: 16
                    color: "#EAE3EE"
                    border.width: 1
                    border.color: win.cOutline

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 12
                        clip: true
                        TextArea {
                            readOnly: true
                            text: backend ? backend.logText : ""
                            font.family: "monospace"
                            font.pixelSize: 11
                            color: win.cInk
                            wrapMode: TextEdit.Wrap
                            background: null
                            onTextChanged: cursorPosition = length
                        }
                    }
                }
            }

            OobePillButton {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                implicitWidth: 220
                text: win.showLogs
                    ? (win.isPl ? "Ukryj szczegóły" : "Hide details")
                    : (win.isPl ? "Pokaż szczegóły" : "Show details")
                outlined: true
                onClicked: win.showLogs = !win.showLogs
            }

            M3CloverBadge {
                anchors.right: parent.right
                anchors.rightMargin: 95
                anchors.top: parent.top
                anchors.topMargin: 64
                width: 210
                height: 210
                spinning: true
                centerSymbol: Math.round((backend ? backend.progress : 0) * 100) + "%"
            }

            ColumnLayout {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 24
                spacing: 10

                OobeSquigglyProgress {
                    progress: backend ? backend.progress : 0.0
                    active: backend ? backend.isBusy : false
                }
            }
        }

        // ---------------------------------------------------------------------
        // STEP 3: ALL SET + "CO DALEJ?" QUICK START GUIDE
        // ---------------------------------------------------------------------
        Item {
            anchors.fill: parent
            visible: win.stepIndex === 3
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 220 } }

            // Left Column: Title + Quick Start Cards ("Co dalej?")
            ColumnLayout {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: 500
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: win.installSucceeded
                        ? (win.isPl ? "Wszystko gotowe!" : "You're all set!")
                        : (win.isPl ? "Wystąpił problem" : "Something went wrong")
                    font.family: win.fontMain
                    font.pixelSize: 38
                    font.weight: Font.Normal
                    color: win.cInk
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: win.installSucceeded
                        ? (win.isPl
                            ? "Twój pulpit został skonfigurowany z presetem DoodlebookOS, a kopia zapasowa poprzednich ustawień została zapisana. Co warto wiedzieć na start:"
                            : "Your desktop is now configured with the DoodlebookOS preset, and a backup of your previous settings was saved. Quick start tips:")
                        : (backend ? backend.statusPl : "")
                    font.family: win.fontMain
                    font.pixelSize: 13
                    lineHeight: 1.38
                    color: win.cSub
                }

                OobeGuideCard {
                    visible: win.installSucceeded
                    badgeSymbol: "❖"
                    titleText: win.isPl
                        ? "Klawisz Super (Meta) — Szuflada aplikacji"
                        : "Super (Meta) Key — App Launcher"
                    bodyText: win.isPl
                        ? "Naciśnij klawisz Super/Windows lub kliknij pierwszą ikonę w docku, aby otworzyć pełnoekranowy launcher i wyszukiwarkę."
                        : "Press the Super/Windows key or click the launcher button on the dock to open the fullscreen app drawer and search."
                }

                OobeGuideCard {
                    visible: win.installSucceeded
                    badgeSymbol: "✦"
                    titleText: win.isPl
                        ? "Górny pasek, Szybkie ustawienia i Multimedia"
                        : "Top Bar, Quick Settings & Media"
                    bodyText: win.isPl
                        ? "Kliknij zegar po lewej, aby otworzyć kalendarz, lub pigułki w prawym górnym rogu, aby sterować Wi-Fi, dźwiękiem, powiadomieniami i kafelkami."
                        : "Click the clock on the left for the calendar, or the top-right pills for notifications, media controls, Wi-Fi, audio, and Quick Settings tiles."
                }

                OobeGuideCard {
                    visible: win.installSucceeded
                    badgeSymbol: "↺"
                    titleText: win.isPl
                        ? "Menu pulpitu i zalecane przelogowanie"
                        : "Desktop Menu & Fresh Session"
                    bodyText: win.isPl
                        ? "Kliknij prawym przyciskiem myszy na pulpicie, aby szybko zmienić tapetę lub dodać widżety. Na świeżym koncie zalecamy jedno wylogowanie i ponowne zalogowanie."
                        : "Right-click anywhere on the desktop to quickly switch wallpapers or add widgets. Logging out and back in once is recommended on a fresh install."
                }

                Item { Layout.fillHeight: true }
            }

            // Right Column: Clover Checkmark + Logout / Finish Buttons
            M3CloverBadge {
                anchors.right: parent.right
                anchors.rightMargin: 110
                anchors.top: parent.top
                anchors.topMargin: 16
                width: 160
                height: 160
                centerSymbol: win.installSucceeded ? "✓" : "!"
            }

            ColumnLayout {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: 12

                property bool logCopied: false

                OobeSwitchCard {
                    visible: win.installSucceeded
                    checked: backend ? backend.isDarkTheme : false
                    badgeSymbol: "🌙"
                    titleText: win.isPl ? "Ciemny motyw (Dark Mode)" : "Dark Theme (Dark Mode)"
                    bodyText: win.isPl
                        ? "Przełącz schemat pulpitu i tapetę na ciemne."
                        : "Switch desktop colors and wallpaper to dark."
                    cliText: win.isPl
                        ? "Terminal: dostheme dark / light"
                        : "CLI: dostheme dark / light"
                    onToggled: isChecked => {
                        if (backend) {
                            backend.setDarkTheme(isChecked);
                        }
                    }
                }

                OobePillButton {
                    implicitWidth: 380
                    text: parent.logCopied
                        ? (win.isPl ? "✓ Skopiowano log instalacji!" : "✓ Installation log copied!")
                        : (win.isPl ? "Kopiuj cały log instalacji" : "Copy entire installation log")
                    outlined: true
                    onClicked: {
                        backend.copyLogToClipboard();
                        parent.logCopied = true;
                    }
                }

                OobePillButton {
                    visible: win.installSucceeded
                    implicitWidth: 380
                    text: win.isPl
                        ? "Wyloguj się teraz (Zalecane na czystym systemie)"
                        : "Log out now (Recommended on fresh install)"
                    outlined: false
                    onClicked: backend.logoutSession()
                }

                OobePillButton {
                    implicitWidth: 380
                    text: win.isPl ? "Zakończ i korzystaj teraz" : "Finish and use now"
                    outlined: win.installSucceeded
                    onClicked: Qt.quit()
                }
            }
        }
    }
}

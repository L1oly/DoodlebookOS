/*
 * SPDX-FileCopyrightText: 2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    fullRepresentation: Item {
        id: container
        implicitWidth: 220
        implicitHeight: 220

        readonly property color accent: Kirigami.Theme.highlightColor
        readonly property color bgColor: Kirigami.Theme.backgroundColor
        readonly property color hourColor: Qt.tint("#182042", Qt.rgba(accent.r, accent.g, accent.b, 0.85))
        readonly property color minuteColor: Qt.tint("#d8dbe9", Qt.rgba(accent.r, accent.g, accent.b, 0.25))
        readonly property color secondDotColor: Qt.tint("#cfb3c8", Qt.rgba(accent.r, accent.g, accent.b, 0.40))

        property var currentDate: new Date()
        readonly property real baseSize: Math.min(width, height)

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                container.currentDate = new Date()
            }
        }

        // Material 3 Expressive 12-sided cookie background
        Image {
            id: cookieImg
            anchors.centerIn: parent
            width: Math.floor(container.baseSize * 0.94)
            height: width
            source: "assets/12-sided-cookie.svg"
            sourceSize: Qt.size(width, height)
            smooth: true
            mipmap: true
            visible: false
        }

        MultiEffect {
            anchors.fill: cookieImg
            source: cookieImg
            colorization: 1.0
            colorizationColor: container.bgColor
        }

        // Shared hands center axis (0, 0)
        Item {
            id: clockCenter
            anchors.centerIn: parent
            width: 1
            height: 1
            z: 1

            // 1. Hour hand
            Item {
                rotation: {
                    var hours = container.currentDate.getHours() % 12;
                    var minutes = container.currentDate.getMinutes();
                    return (hours * 30) + (minutes * 0.5);
                }
                z: 1

                Rectangle {
                    // Same thickness as minute hand (90% of base):
                    readonly property real baseHandW: Math.max(7, Math.round(container.baseSize * 0.075))
                    readonly property real handW: Math.round(baseHandW * 0.9)

                    width: handW
                    height: Math.round(container.baseSize * 0.20) + (handW / 2)
                    radius: handW / 2
                    color: container.hourColor
                    x: -width / 2
                    y: -height + (handW / 2)
                    antialiasing: true
                }
            }

            // 2. Minute hand
            Item {
                rotation: {
                    var minutes = container.currentDate.getMinutes();
                    var seconds = container.currentDate.getSeconds();
                    return (minutes * 6) + (seconds * 0.1);
                }
                z: 2

                Rectangle {
                    // Width calculation: 90% of base thickness
                    readonly property real baseHandW: Math.max(7, Math.round(container.baseSize * 0.075))
                    readonly property real handW: Math.round(baseHandW * 0.9)

                    width: handW
                    height: Math.round(container.baseSize * 0.26) + (handW / 2)
                    radius: handW / 2
                    color: container.minuteColor
                    x: -width / 2
                    y: -height + (handW / 2)
                    antialiasing: true
                }
            }

            // 3. Second dot
            Item {
                rotation: container.currentDate.getSeconds() * 6
                z: 3

                Rectangle {
                    readonly property real dotD: Math.max(7, Math.round(container.baseSize * 0.075))
                    width: dotD
                    height: dotD
                    radius: dotD / 2
                    color: container.secondDotColor
                    x: -width / 2
                    y: -Math.round(container.baseSize * 0.35)
                    antialiasing: true
                }
            }

        }
    }
}

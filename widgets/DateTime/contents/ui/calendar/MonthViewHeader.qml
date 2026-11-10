/*
    SPDX-FileCopyrightText: 2022 Tanbir Jishan <tantalising007@gmail.com>
    SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>

    SPDX-License-Identifier: GPL-3.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import QtQuick.Effects
import "../i18n.js" as I18n

Item {
    id: root

    function i18nd(d, k, a1, a2) { return I18n.t(k, a1, a2); }

    required property T.SwipeView swipeView
    required property QtObject monthViewRoot

    readonly property T.AbstractButton previousButton: prevBtn
    readonly property alias monthYearButton: monthYearBtn

    implicitWidth: viewHeader.implicitWidth
    implicitHeight: viewHeader.implicitHeight

    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1.0
    function snap(val) {
        return Math.round(val * dpr) / dpr;
    }

    KeyNavigation.up: monthYearBtn

    RowLayout {
        id: viewHeader
        anchors {
            fill: parent
            leftMargin: Kirigami.Units.largeSpacing + snap(10.4)
            rightMargin: Kirigami.Units.largeSpacing + snap(8.0)
        }
        spacing: Kirigami.Units.smallSpacing

        // Entire row on the left is a button with Month + Year + Down arrow icon
        PlasmaComponents.ItemDelegate {
            id: monthYearBtn
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            hoverEnabled: true

            background: Rectangle {
                radius: 8
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, monthYearBtn.pressed ? 0.20 : (monthYearBtn.hovered ? 0.12 : 0))
                Behavior on color {
                    ColorAnimation { duration: Kirigami.Units.shortDuration }
                }
            }

            contentItem: RowLayout {
                spacing: 6

                Text {
                    id: heading
                    objectName: "monthHeader"
                    text: {
                        const m = (root.monthViewRoot as MonthView).selectedMonth;
                        const monthCap = m ? m.charAt(0).toUpperCase() + m.slice(1) : "";
                        const y = (root.monthViewRoot as MonthView).selectedYear;
                        return monthCap + " " + y;
                    }
                    textFormat: Text.PlainText
                    font {
                        family: "Google Sans Flex"
                        weight: 600
                        pixelSize: (typeof root.monthViewRoot !== "undefined" && root.monthViewRoot && root.monthViewRoot.calendarFontPixelSize > 0)
                            ? root.monthViewRoot.calendarFontPixelSize
                            : 12.8
                    }
                    renderType: Text.QtRendering
                    color: (monthYearBtn.hovered || monthYearBtn.pressed) ? Kirigami.Theme.activeTextColor : Kirigami.Theme.textColor
                    elide: Text.ElideRight
                    Layout.alignment: Qt.AlignVCenter
                }

                Item {
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    Layout.alignment: Qt.AlignVCenter
                    rotation: root.swipeView.currentIndex === 0 ? 0 : 180
                    Behavior on rotation { NumberAnimation { duration: Kirigami.Units.shortDuration } }

                    Image {
                        id: arrowDownImg
                        anchors.fill: parent
                        sourceSize: Qt.size(32, 32)
                        source: Qt.resolvedUrl("../icons/arrow_drop_down.svg")
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: arrowDownImg
                        colorization: 1.0
                        colorizationColor: Kirigami.Theme.textColor
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            onClicked: {
                if (root.swipeView.currentIndex === 0) {
                    (root.monthViewRoot as MonthView).showYearView();
                } else {
                    (root.monthViewRoot as MonthView).showMonthView();
                }
            }
        }

        // Navigation buttons on the right: left arrow and right arrow
        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

            PlasmaComponents.ToolButton {
                id: prevBtn
                text: {
                    switch ((root.monthViewRoot as MonthView).calendarViewDisplayed) {
                    case MonthView.CalendarView.DayView:
                        return i18nd("plasmashellprivateplugin", "Previous Month");
                    case MonthView.CalendarView.MonthView:
                        return i18nd("plasmashellprivateplugin", "Previous Year");
                    case MonthView.CalendarView.YearView:
                        return i18nd("plasmashellprivateplugin", "Previous Decade");
                    default:
                        return "";
                    }
                }
                display: T.AbstractButton.IconOnly
                onClicked: (root.monthViewRoot as MonthView).previousView()
                PlasmaComponents.ToolTip { text: prevBtn.text }

                background: Rectangle {
                    radius: 8
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, prevBtn.pressed ? 0.20 : (prevBtn.hovered ? 0.12 : 0))
                    Behavior on color {
                        ColorAnimation { duration: Kirigami.Units.shortDuration }
                    }
                }

                contentItem: Item {
                    implicitWidth: 24
                    implicitHeight: 24

                    Image {
                        id: prevArrowImg
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        sourceSize: Qt.size(48, 48)
                        fillMode: Image.PreserveAspectFit
                        source: Qt.resolvedUrl(Application.layoutDirection === Qt.RightToLeft ? "../icons/keyboard_arrow_right.svg" : "../icons/keyboard_arrow_left.svg")
                        smooth: true
                        mipmap: true
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: prevArrowImg
                        source: prevArrowImg
                        colorization: 1.0
                        colorizationColor: Kirigami.Theme.textColor
                        opacity: prevBtn.enabled ? (prevBtn.pressed ? 0.7 : 1.0) : 0.4
                    }
                }
            }

            PlasmaComponents.ToolButton {
                id: nextBtn
                text: {
                    switch ((root.monthViewRoot as MonthView).calendarViewDisplayed) {
                    case MonthView.CalendarView.DayView:
                        return i18nd("plasmashellprivateplugin", "Next Month");
                    case MonthView.CalendarView.MonthView:
                        return i18nd("plasmashellprivateplugin", "Next Year");
                    case MonthView.CalendarView.YearView:
                        return i18nd("plasmashellprivateplugin", "Next Decade");
                    default:
                        return "";
                    }
                }
                display: T.AbstractButton.IconOnly
                onClicked: (root.monthViewRoot as MonthView).nextView()
                PlasmaComponents.ToolTip { text: nextBtn.text }

                background: Rectangle {
                    radius: 8
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, nextBtn.pressed ? 0.20 : (nextBtn.hovered ? 0.12 : 0))
                    Behavior on color {
                        ColorAnimation { duration: Kirigami.Units.shortDuration }
                    }
                }

                contentItem: Item {
                    implicitWidth: 24
                    implicitHeight: 24

                    Image {
                        id: nextArrowImg
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        sourceSize: Qt.size(48, 48)
                        fillMode: Image.PreserveAspectFit
                        source: Qt.resolvedUrl(Application.layoutDirection === Qt.RightToLeft ? "../icons/keyboard_arrow_left.svg" : "../icons/keyboard_arrow_right.svg")
                        smooth: true
                        mipmap: true
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: nextArrowImg
                        source: nextArrowImg
                        colorization: 1.0
                        colorizationColor: Kirigami.Theme.textColor
                        opacity: nextBtn.enabled ? (nextBtn.pressed ? 0.7 : 1.0) : 0.4
                    }
                }
            }
        }
    }
}

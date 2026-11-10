/*
    SPDX-FileCopyrightText: 2013 Heena Mahour <heena393@gmail.com>
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2015 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2021 Jan Blackquill <uhhadd@gmail.com>
    SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
    SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>

    SPDX-License-Identifier: GPL-3.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.workspace.calendar as PlasmaCalendar

PlasmaComponents.AbstractButton {
    id: dayStyle

    required property int index
    /*
     * Possible row types:
     *
     * - year: ListModel
     *   * label: string
     *   * yearNumber: int
     *   * isCurrent: bool
     * - month: ListModel
     *   * label: string
     *   * monthNumber: int
     *   * yearNumber: int
     *   * isCurrent: bool
     * - day: PlasmaCalendar.DaysModel
     *   * no "label" role
     */
    required property var model

    // These two roles are defined for all row types. Other roles would have
    // to be fetched through the `model` row object.
    required property bool isCurrent
    required property int yearNumber

    required property /*PlasmaCalendar.Calendar.DateMatchingPrecision*/int dateMatchingPrecision

    /*
     * The layout of this button is
     * [eventIndicatorsRow]
     * [label]
     * [subDayLabel]
     */
    property double calendarFontPixelSize: 12.8
    property double mainLabelFontPixelSize: calendarFontPixelSize > 0 ? calendarFontPixelSize : Math.max(
        Kirigami.Theme.defaultFont.pixelSize * 1.35 /* Level 1 Heading */,
        height / (dateMatchingPrecision === PlasmaCalendar.Calendar.MatchYearMonthAndDay ? 3 /* weeksColumn */ : 6))
    property double eventIndicatorsRowSize: Math.min(
        Kirigami.Units.smallSpacing,
        height / 6
    )
    // This is set to such that `subDayLabel` does not overlap with `label`
    // and `eventIndicatorsRow`.
    property double subDayLabelFontPixelSize: Math.min(
        Math.max(
            Kirigami.Theme.smallFont.pixelSize,
            height / (dateMatchingPrecision === PlasmaCalendar.Calendar.MatchYearMonthAndDay ? 6 : 12)),
        (height - mainLabelFontPixelSize) / 2 - eventIndicatorsRowSize
    )

    objectName: {
        switch (dateMatchingPrecision) {
        case PlasmaCalendar.Calendar.MatchYear:
            return "calendarCell-" + yearNumber;
        case PlasmaCalendar.Calendar.MatchYearAndMonth:
            return "calendarCell-" + yearNumber + "-" + model.monthNumber;
        case PlasmaCalendar.Calendar.MatchYearMonthAndDay:
        default:
            return "calendarCell-" + yearNumber + "-" + model.monthNumber + "-" + model.dayNumber;
        }
    }
    hoverEnabled: isCurrent
    enabled: isCurrent

    // type: either PlasmaCalendar.DaysModel or an equivalent ListModel
    required property QtObject dayModel

    readonly property date thisDate: {
        const monthNumber = (dateMatchingPrecision >= PlasmaCalendar.Calendar.MatchYearAndMonth) ? model.monthNumber - 1 : 0;
        const dayNumber = (dateMatchingPrecision >= PlasmaCalendar.Calendar.MatchYearMonthAndDay) ? model.dayNumber : 1;
        return new Date(yearNumber, monthNumber, dayNumber);
    }

    Accessible.name: dayStyle.isCurrent ? thisDate.toLocaleDateString(Qt.locale(), Locale.LongFormat) : ""
    Accessible.description: {
        if (!dayStyle.isCurrent) return "";
        const eventDescription = (model.eventCount !== undefined && model.eventCount > 0)
            ? i18ndp("plasmashellprivateplugin", "%1 event", "%1 events", model.eventCount)
            : i18nd("plasmashellprivateplugin", "No events");
        const subLabelDescription = model.subLabel || model.subDayLabel || "";
        return `${eventDescription} ${subLabelDescription ? `; ${subLabelDescription}` : ""}`;
    }

    readonly property bool today: {
        const today = root.today;
        let result = true;
        if (dateMatchingPrecision >= PlasmaCalendar.Calendar.MatchYear) {
            result &= today.getFullYear() === thisDate.getFullYear();
        }
        if (dateMatchingPrecision >= PlasmaCalendar.Calendar.MatchYearAndMonth) {
            result &= today.getMonth() === thisDate.getMonth();
        }
        if (dateMatchingPrecision >= PlasmaCalendar.Calendar.MatchYearMonthAndDay) {
            result &= today.getDate() === thisDate.getDate();
        }
        return result;
    }
    readonly property bool selected: {
        const current = root.currentDate;
        let result = true;
        if (dateMatchingPrecision >= PlasmaCalendar.Calendar.MatchYear) {
            result &= current.getFullYear() === thisDate.getFullYear();
        }
        if (dateMatchingPrecision >= PlasmaCalendar.Calendar.MatchYearAndMonth) {
            result &= current.getMonth() === thisDate.getMonth();
        }
        if (dateMatchingPrecision >= PlasmaCalendar.Calendar.MatchYearMonthAndDay) {
            result &= current.getDate() === thisDate.getDate();
        }
        return result;
    }

    readonly property color onPrimaryColor: Kirigami.Theme.highlightedTextColor

    background: Item {
        Rectangle {
            id: selectionHighlight
            anchors.centerIn: parent
            readonly property bool isDayView: dayStyle.dateMatchingPrecision === PlasmaCalendar.Calendar.MatchYearMonthAndDay
            width: isDayView ? Math.min(Math.min(parent.width, parent.height) - 4, 34) : parent.width - 8
            height: isDayView ? width : parent.height - 8
            radius: isDayView ? (width / 2) : 10
            visible: dayStyle.isCurrent

            color: {
                if (dayStyle.selected) {
                    return Kirigami.Theme.highlightColor;
                } else if (dayStyle.pressed) {
                    return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.20);
                } else if (dayStyle.hovered || dayStyle.activeFocus) {
                    return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12);
                } else {
                    return "transparent";
                }
            }

            border.color: (dayStyle.today && !dayStyle.selected) ? Kirigami.Theme.textColor : "transparent"
            border.width: (dayStyle.today && !dayStyle.selected) ? 1 : 0

            Behavior on color {
                ColorAnimation {
                    duration: Kirigami.Units.shortDuration
                }
            }
        }
    }

    Loader {
        // Basically, only active when dayStyle.dayModel is PlasmaCalendar.DaysModel
        // and thus dateMatchingPrecision is PlasmaCalendar.Calendar.MatchYearMonthAndDay
        active: dayStyle.isCurrent && dayStyle.model.eventCount !== undefined && dayStyle.model.eventCount > 0
        anchors.top: parent.top
        anchors.topMargin: Kirigami.Units.largeSpacing
        anchors.horizontalCenter: parent.horizontalCenter
        sourceComponent: Row {
            id: eventIndicatorsRow

            spacing: Kirigami.Units.smallSpacing

            Repeater {
                id: eventIndicatorsRepeater
                readonly property int maxDots: 5
                model: DelegateModel {
                    model: dayStyle.dayModel
                    delegate: Rectangle {
                        // If there are <= maxDots events for the day, show them as individual dots.
                        // Otherwise, show a little bar to not overflow the box.
                        visible: eventIndicatorsRepeater.count <= eventIndicatorsRepeater.maxDots
                        required property string eventColor

                        width: dayStyle.eventIndicatorsRowSize
                        height: width
                        radius: width / 2
                        color: dayStyle.selected
                            ? dayStyle.onPrimaryColor
                            : (eventColor
                                ? Kirigami.ColorUtils.linearInterpolation(eventColor, Kirigami.Theme.textColor, 0.05)
                                : Kirigami.Theme.highlightColor)
                    }

                    Component.onCompleted: {
                        rootIndex = modelIndex(dayStyle.index);
                    }
                }
            }
            Rectangle {
                visible: eventIndicatorsRepeater.count > eventIndicatorsRepeater.maxDots
                width: dayStyle.width * 0.5
                height: dayStyle.eventIndicatorsRowSize
                radius: height / 2
                color: dayStyle.selected ? dayStyle.onPrimaryColor : Kirigami.Theme.highlightColor
            }
        }
    }

    contentItem: Item {
        // ColumnLayout makes scrolling too slow, so use anchors to position labels

        PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
        PlasmaComponents.ToolTip.text: dayStyle.isCurrent ? (dayStyle.model.subLabel || "") : ""
        PlasmaComponents.ToolTip.visible: dayStyle.isCurrent && !!dayStyle.model.subLabel && (Kirigami.Settings.isMobile ? dayStyle.pressed : dayStyle.hovered)

        PlasmaComponents.Label {
            id: label
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }
            font.pixelSize: dayStyle.mainLabelFontPixelSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: dayStyle.isCurrent ? (dayStyle.model.label || dayStyle.model.dayLabel) : ""
            textFormat: Text.PlainText
            color: dayStyle.selected ? dayStyle.onPrimaryColor : Kirigami.Theme.textColor
            font.weight: Font.Normal
            opacity: 1.0
            visible: dayStyle.isCurrent
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }

        // This is always displayed to align the position of eventIndicatorsRow
        // even when it is empty.
        Loader {
            id: subDayLabel
            anchors {
                left: parent.left
                right: parent.right
                top: parent.bottom
            }
            asynchronous: true
            opacity: 0
            visible: dayStyle.isCurrent
            active: dayStyle.isCurrent

            sourceComponent: PlasmaComponents.Label {
                elide: Text.ElideRight
                font.pixelSize: dayStyle.subDayLabelFontPixelSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                maximumLineCount: 1
                opacity: 0.85
                color: dayStyle.selected ? dayStyle.onPrimaryColor : Kirigami.Theme.textColor
                font.weight: Font.Normal
                // Prefer sublabel over day number
                text: dayStyle.model.subDayLabel || dayStyle.model.alternateDayNumber?.toString() || ''
                textFormat: Text.PlainText
                wrapMode: Text.NoWrap
            }

            states: State {
                when: subDayLabel.status === Loader.Ready && subDayLabel.implicitHeight > 1
                AnchorChanges {
                    target: subDayLabel
                    anchors.top: undefined
                    anchors.bottom: subDayLabel.parent.bottom
                }
                PropertyChanges {
                    subDayLabel.opacity: 1
                }
            }

            transitions: Transition {
                NumberAnimation {
                    property: "opacity"
                    easing.type: Easing.OutCubic
                    duration: Kirigami.Units.longDuration
                }
                AnchorAnimation {
                    easing.type: Easing.OutCubic
                    duration: Kirigami.Units.longDuration
                }
            }
        }

        Component.onCompleted: {
            if (dayStyle.today) {
                root.todayAuxilliaryText = Qt.binding(() => dayStyle.model.subLabel || "");
            }
        }
    }
}

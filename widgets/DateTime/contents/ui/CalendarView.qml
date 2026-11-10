/*
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2015 Martin Klapetek <mklapetek@kde.org>
    SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
    SPDX-FileCopyrightText: 2023 ivan tkachenko <me@ratijas.tk>
    SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>

    SPDX-License-Identifier: GPL-3.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import "calendar" as CustomCalendar

// Pure Single-Column Month View (No agenda, no additional clocks)
PlasmaExtras.Representation {
    id: calendar

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: true

    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1.0
    function snap(val) {
        return Math.round(val * dpr) / dpr;
    }

    // 423 px fizycznych przy skali 125% (338.4 dp):
    readonly property real baseCalendarWidth: snap(338.4)
    // 441 px fizycznych przy skali 125% (352.8 dp):
    readonly property real baseCalendarHeight: snap(352.8)
    readonly property real calendarFontPixelSize: (typeof root !== "undefined" && root && root.calendarFontPixelSize > 0)
        ? root.calendarFontPixelSize
        : snap(snap(32.0 * 0.675) * (16.0 / 27.0))

    Layout.preferredWidth: baseCalendarWidth
    Layout.minimumWidth: baseCalendarWidth
    Layout.maximumWidth: baseCalendarWidth

    Layout.preferredHeight: baseCalendarHeight
    Layout.minimumHeight: baseCalendarHeight
    Layout.maximumHeight: baseCalendarHeight

    implicitWidth: baseCalendarWidth
    implicitHeight: baseCalendarHeight
    width: baseCalendarWidth
    height: baseCalendarHeight

    readonly property alias monthView: monthView
    readonly property double headerHeight: monthView.viewHeader.implicitHeight

    PlasmaCalendar.EventPluginsManager {
        id: eventPluginsManager
        enabledPlugins: Plasmoid.configuration.enabledCalendarPlugins
    }

    Binding {
        when: calendar.Window && calendar.Window.window !== null
        target: calendar.Window ? calendar.Window.window : null
        property: "margin"
        value: 1
    }
    Binding {
        when: calendar.Window && calendar.Window.window !== null
        target: calendar.Window ? calendar.Window.window : null
        property: "width"
        value: calendar.baseCalendarWidth
    }
    Binding {
        when: calendar.Window && calendar.Window.window !== null
        target: calendar.Window ? calendar.Window.window : null
        property: "height"
        value: calendar.baseCalendarHeight
    }
    Binding {
        when: calendar.Window && calendar.Window.window !== null
        target: calendar.Window ? calendar.Window.window : null
        property: "minimumWidth"
        value: calendar.baseCalendarWidth
    }
    Binding {
        when: calendar.Window && calendar.Window.window !== null
        target: calendar.Window ? calendar.Window.window : null
        property: "maximumWidth"
        value: calendar.baseCalendarWidth
    }
    Binding {
        when: calendar.Window && calendar.Window.window !== null
        target: calendar.Window ? calendar.Window.window : null
        property: "minimumHeight"
        value: calendar.baseCalendarHeight
    }
    Binding {
        when: calendar.Window && calendar.Window.window !== null
        target: calendar.Window ? calendar.Window.window : null
        property: "maximumHeight"
        value: calendar.baseCalendarHeight
    }

    function adjustWindowPosition() {
        var win = calendar.Window ? calendar.Window.window : null;
        if (!win || !win.visible || !win.screen) return;
        win.minimumWidth = calendar.baseCalendarWidth;
        win.maximumWidth = calendar.baseCalendarWidth;
        win.minimumHeight = calendar.baseCalendarHeight;
        win.maximumHeight = calendar.baseCalendarHeight;
        win.width = calendar.baseCalendarWidth;
        win.height = calendar.baseCalendarHeight;
        var screenW = win.screen.geometry.width;
        var screenH = win.screen.geometry.height;
        var screenX = win.screen.geometry.x;
        var screenY = win.screen.geometry.y;
        var rightEdge = screenX + screenW;
        var bottomEdge = screenY + screenH;
        var offset = 8;

        if (win.x < screenX + offset) {
            win.x = screenX + offset;
        } else if ((win.x + win.width) > (rightEdge - offset)) {
            win.x = rightEdge - win.width - offset;
        }

        if (win.y < screenY + offset) {
            win.y = screenY + offset;
        } else if ((win.y + win.height) > (bottomEdge - offset)) {
            win.y = bottomEdge - win.height - offset;
        }
    }

    Connections {
        target: calendar.Window ? calendar.Window.window : null
        function onVisibleChanged() {
            var win = calendar.Window ? calendar.Window.window : null;
            if (win && win.visible) {
                Qt.callLater(calendar.adjustWindowPosition);
            }
        }
    }

    header: null

    FocusScope {
        id: monthViewWrapper
        anchors.fill: parent

        CustomCalendar.MonthView {
            id: monthView
            viewHeader.height: calendar.headerHeight

            anchors {
                fill: parent
                leftMargin: Kirigami.Units.smallSpacing
                rightMargin: Kirigami.Units.smallSpacing
                bottomMargin: Kirigami.Units.smallSpacing
            }

            eventPluginsManager: eventPluginsManager
            today: root.currentTime
            firstDayOfWeek: Plasmoid.configuration.firstDayOfWeek > -1
                ? Plasmoid.configuration.firstDayOfWeek
                : Qt.locale().firstDayOfWeek
            showWeekNumbers: Plasmoid.configuration.showWeekNumbers

            showDigitalClockHeader: true
            calendarFontPixelSize: calendar.calendarFontPixelSize

            KeyNavigation.left: KeyNavigation.tab
            KeyNavigation.tab: viewHeader.previousButton
            Keys.onUpPressed: viewHeader.previousButton.forceActiveFocus(Qt.BacktabFocusReason);
        }
    }
}

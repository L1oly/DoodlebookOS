/*
    SPDX-FileCopyrightText: 2018-2019 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2026 DoodlebookOS

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtQuick
import org.kde.notificationmanager as NotificationManager

QtObject {
    id: root

    property int index
    property int notificationType

    property var applicationIconSource
    property string applicationName
    property string originName

    property string summary
    property var time

    property bool configurable
    property bool dismissable
    property bool dismissed
    property bool closable

    property string body
    property string accessibleDescription
    property var icon
    property var image
    property list<url> urls: []
    property int urgency: NotificationManager.Notifications.NormalUrgency

    property int jobState
    property int percentage

    property string configureActionLabel
    property list<string> actionNames: []
    property list<string> actionLabels: []
    property bool hasDefaultAction
    property bool hasSomeActions

    property bool hasReplyAction
    property string replyActionLabel
    property string replyPlaceholderText
    property bool replying: false
    property bool hasPendingReply: false

    property real timeout

    signal bodyClicked
    signal closeClicked
    signal configureClicked
    signal dismissClicked
    signal actionInvoked(string actionName)
    signal defaultActionInvoked
    signal replied(string text)
    signal openUrl(string url)
}

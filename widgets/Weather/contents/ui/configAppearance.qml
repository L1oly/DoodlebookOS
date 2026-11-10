/*
 * SPDX-FileCopyrightText: 2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

KCMUtils.SimpleKCM {
    id: page

    property alias cfg_cityName: cityField.text

    Kirigami.FormLayout {
        QQC2.TextField {
            id: cityField
            Kirigami.FormData.label: "City:"
            placeholderText: "Auto-detect by IP (or enter e.g. London, Warsaw, Tokyo)"
            Layout.fillWidth: true
        }
    }
}

/*
 * SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "i18n.js" as I18n

Item {
    id: delegateRoot
    function i18n(k, a1, a2) { return I18n.t(k, a1, a2); }

    required property var model
    required property int index

    readonly property bool isCurrent: ListView.isCurrentItem
    readonly property var actionsList: (typeof delegateRoot.model !== "undefined" && delegateRoot.model && delegateRoot.model.actionList) ? delegateRoot.model.actionList : []

    function resolveActionIcon(act) {
        if (!act) return Qt.resolvedUrl("icons/action_default.svg");
        var aId = (act.id || act.actionId || "").toString().toLowerCase();
        var aTxt = (act.text || "").toString().toLowerCase();

        // 1. Incognito / Private Window
        if (aId.includes("incognito") || aId.includes("private") || aTxt.includes("incognito") || aTxt.includes("prywatn")) {
            return Qt.resolvedUrl("icons/action_incognito.svg");
        }
        // 2. New Tab
        if (aId.includes("tab") || aTxt.includes("kart")) {
            return Qt.resolvedUrl("icons/action_new_tab.svg");
        }
        // 3. New Document / File
        if (aId.includes("document") || aTxt.includes("dokument") || (aTxt.includes("nowy") && !aTxt.includes("okn"))) {
            return Qt.resolvedUrl("icons/action_new_document.svg");
        }
        // 4. New Window
        if (aId.includes("window") || aTxt.includes("okn") || aId === "new-window") {
            return Qt.resolvedUrl("icons/action_new_window.svg");
        }
        // 5. Open Folder
        if (aId.includes("folder") || aTxt.includes("folder") || aTxt.includes("katalog")) {
            return Qt.resolvedUrl("icons/action_open_folder.svg");
        }
        // 6. Copy
        if (aId.includes("copy") || aTxt.includes("kopiuj")) {
            return Qt.resolvedUrl("icons/action_copy.svg");
        }
        // 7. Terminal
        if (aId.includes("terminal") || aTxt.includes("terminal")) {
            return Qt.resolvedUrl("icons/action_terminal.svg");
        }
        // 8. Admin / Root
        if (aId.includes("root") || aId.includes("admin") || aTxt.includes("administrator")) {
            return Qt.resolvedUrl("icons/action_admin.svg");
        }
        // 9. Existing valid custom icon if provided
        if (act.iconSource && act.iconSource.length > 0 && act.iconSource !== "system-run") {
            return act.iconSource;
        }
        return Qt.resolvedUrl("icons/action_default.svg");
    }

    readonly property bool isShellCommand: {
        if (!delegateRoot.model) return false;
        var grp = (delegateRoot.model.group || "").toString().toLowerCase();
        if (grp === "wiersz poleceń" || grp === "command line" || grp === "command") return true;
        if (delegateRoot.actionsList && delegateRoot.actionsList.length > 0) {
            for (var i = 0; i < delegateRoot.actionsList.length; i++) {
                var act = delegateRoot.actionsList[i];
                var aId = (act.id || act.actionId || "").toString();
                var aTxt = (act.text || "").toString().toLowerCase();
                if (aId === "run-in-terminal" || aTxt.includes("terminal")) return true;
            }
        }
        return false;
    }

    readonly property bool isCalculator: {
        if (!delegateRoot.model) return false;
        var grp = (delegateRoot.model.group || "").toString().toLowerCase();
        return (grp === "kalkulator" || grp === "calculator");
    }

    readonly property var filteredActionsList: {
        if (!delegateRoot.actionsList || delegateRoot.actionsList.length === 0) return [];
        if (delegateRoot.isShellCommand) {
            // For shell command, primary action is already terminal. Filter out run-in-terminal so we don't duplicate the button!
            var list = [];
            for (var i = 0; i < delegateRoot.actionsList.length; i++) {
                var act = delegateRoot.actionsList[i];
                var aId = (act.id || act.actionId || "").toString();
                var aTxt = (act.text || "").toString().toLowerCase();
                if (aId !== "run-in-terminal" && !aTxt.includes("terminal")) {
                    list.push(act);
                }
            }
            return list.slice(0, 2);
        }
        return delegateRoot.actionsList.slice(0, 2);
    }

    width: ListView.view ? ListView.view.width : 0
    implicitHeight: 46
    height: implicitHeight

    function runPrimary() {
        if (!ListView.view || !ListView.view.model || typeof ListView.view.model.trigger !== "function") return;

        // 1. Shell command -> Run in terminal by default (keeps open with --noclose)
        if (delegateRoot.isShellCommand && delegateRoot.actionsList && delegateRoot.actionsList.length > 0) {
            for (var i = 0; i < delegateRoot.actionsList.length; i++) {
                var act = delegateRoot.actionsList[i];
                var aId = (act.id || act.actionId || "").toString();
                var aTxt = (act.text || "").toString().toLowerCase();
                if (aId === "run-in-terminal" || aTxt.includes("terminal")) {
                    ListView.view.model.trigger(delegateRoot.index, aId || "run-in-terminal", act.actionArgument || null);
                    if (typeof root !== "undefined" && root && typeof root.closeAnimated === "function") {
                        root.closeAnimated();
                    }
                    return;
                }
            }
        }

        // 2. Calculator -> Trigger copy to clipboard and show OSD notification
        if (delegateRoot.isCalculator) {
            var res = (delegateRoot.model && delegateRoot.model.display) ? delegateRoot.model.display.toString() : "";
            ListView.view.model.trigger(delegateRoot.index, "", null);
            if (typeof searchListRoot !== "undefined" && searchListRoot && typeof searchListRoot.showOsdNotification === "function") {
                searchListRoot.showOsdNotification("edit-copy", delegateRoot.i18n("Copied to clipboard: ") + res);
            }
            if (typeof root !== "undefined" && root && typeof root.closeAnimated === "function") {
                root.closeAnimated();
            }
            return;
        }

        // 3. Default primary trigger
        ListView.view.model.trigger(delegateRoot.index, "", null);
        if (typeof root !== "undefined" && root && typeof root.closeAnimated === "function") {
            root.closeAnimated();
        }
    }

    function runFirstAction() {
        if (!ListView.view || !ListView.view.model || typeof ListView.view.model.trigger !== "function") return;

        // For shell commands, Shift+Enter runs silently in the background
        if (delegateRoot.isShellCommand) {
            ListView.view.model.trigger(delegateRoot.index, "", null);
            if (typeof root !== "undefined" && root && typeof root.closeAnimated === "function") {
                root.closeAnimated();
            }
            return;
        }

        if (delegateRoot.actionsList && delegateRoot.actionsList.length > 0) {
            var act = delegateRoot.actionsList[0];
            ListView.view.model.trigger(delegateRoot.index, act.actionId || "", act.actionArgument || null);
            if (typeof root !== "undefined" && root && typeof root.closeAnimated === "function") {
                root.closeAnimated();
            }
            return;
        }
        delegateRoot.runPrimary();
    }

    Rectangle {
        id: bgCard
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.topMargin: 2
        anchors.bottomMargin: 2
        radius: 8
        color: {
            if (delegateRoot.isCurrent) {
                return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.22);
            }
            if (rowHoverHandler.hovered) {
                return Qt.rgba(1, 1, 1, 0.08);
            }
            return "transparent";
        }

        border.width: delegateRoot.isCurrent ? 1 : 0
        border.color: delegateRoot.isCurrent ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.5) : "transparent"

        Behavior on color {
            ColorAnimation { duration: 100 }
        }
    }

    HoverHandler {
        id: rowHoverHandler
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: {
            if (hovered && ListView.view) {
                ListView.view.currentIndex = delegateRoot.index;
            }
        }
    }

    TapHandler {
        onTapped: {
            if (ListView.view) {
                ListView.view.currentIndex = delegateRoot.index;
            }
            delegateRoot.runPrimary();
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        // Icon
        Kirigami.Icon {
            id: resultIcon
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            Layout.alignment: Qt.AlignVCenter
            source: (typeof delegateRoot.model !== "undefined" && delegateRoot.model && delegateRoot.model.decoration) ? delegateRoot.model.decoration : "system-run"
            smooth: true
        }

        // Texts
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            // Title / display
            QQC2.Label {
                id: titleLabel
                Layout.fillWidth: true
                text: (typeof delegateRoot.model !== "undefined" && delegateRoot.model && delegateRoot.model.display) ? delegateRoot.model.display.toString() : ""
                font.family: (typeof main !== "undefined" && main) ? main.textFont : Kirigami.Theme.defaultFont.family
                font.pointSize: (typeof main !== "undefined" && main) ? main.textSize + 1 : 11
                font.weight: Font.DemiBold
                color: delegateRoot.isCurrent ? Kirigami.Theme.highlightColor : ((typeof main !== "undefined" && main) ? main.textColor : Kirigami.Theme.textColor)
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            // Subtitle / description / path
            QQC2.Label {
                id: descLabel
                Layout.fillWidth: true
                text: {
                    if (delegateRoot.isShellCommand) {
                        return delegateRoot.i18n("Run in terminal window (Shift+Enter: in background)");
                    }
                    if (typeof delegateRoot.model !== "undefined" && delegateRoot.model && delegateRoot.model.description) {
                        return delegateRoot.model.description.toString();
                    }
                    return "";
                }
                visible: text.length > 0 && text !== titleLabel.text
                font.family: (typeof main !== "undefined" && main) ? main.textFont : Kirigami.Theme.defaultFont.family
                font.pointSize: (typeof main !== "undefined" && main) ? Math.max(8, main.textSize - 1) : 9
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.6)
                elide: Text.ElideMiddle
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Inline Actions (visible on current/hovered item)
        RowLayout {
            id: actionsRow
            Layout.alignment: Qt.AlignVCenter
            spacing: 6
            visible: (delegateRoot.isCurrent || rowHoverHandler.hovered) && actionsRepeater.count > 0

            Repeater {
                id: actionsRepeater
                model: delegateRoot.filteredActionsList

                QQC2.ToolButton {
                    id: actBtn
                    required property var modelData
                    required property int index

                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28

                    contentItem: Kirigami.Icon {
                        anchors.centerIn: parent
                        implicitWidth: 16
                        implicitHeight: 16
                        source: delegateRoot.resolveActionIcon(actBtn.modelData)
                        isMask: true
                        color: Kirigami.Theme.textColor
                    }

                    background: Rectangle {
                        radius: 6
                        color: actBtn.hovered ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
                    }

                    QQC2.ToolTip {
                        id: actToolTip
                        visible: actBtn.hovered
                        delay: 350
                        timeout: -1

                        y: -implicitHeight - 6
                        x: Math.round((actBtn.width - implicitWidth) / 2)

                        contentItem: Text {
                            text: {
                                var t = actBtn.modelData.text || "";
                                if (actBtn.index === 0) {
                                    return t + " (Shift+Enter)";
                                }
                                return t;
                            }
                            color: {
                                var panelTextColor = (typeof main !== "undefined" && main) ? main.textColor : Kirigami.Theme.textColor;
                                var isDark = panelTextColor.r > 0.5 || panelTextColor.g > 0.5 || panelTextColor.b > 0.5;
                                return isDark ? "#F4F4F8" : "#1F1F24";
                            }
                            font.family: (typeof main !== "undefined" && main) ? main.textFont : Kirigami.Theme.defaultFont.family
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            renderType: Text.NativeRendering
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Item {
                            id: tipBgItem
                            implicitWidth: Math.max(48, actToolTip.contentItem.implicitWidth + 28)
                            implicitHeight: 34

                            readonly property bool isDarkTheme: Kirigami.Theme.textColor.r > 0.5 || Kirigami.Theme.textColor.g > 0.5 || Kirigami.Theme.textColor.b > 0.5
                            readonly property color bubbleColor: {
                                var bg = (typeof main !== "undefined" && main) ? main.bgColor : Kirigami.Theme.backgroundColor;
                                if (bg && bg.a > 0 && bg !== "#00000000") return bg;
                                return isDarkTheme ? "#2A2E32" : "#F4F4F8";
                            }

                            // Pill bubble
                            Rectangle {
                                width: parent.width
                                height: 28
                                radius: 14
                                color: tipBgItem.bubbleColor
                                border.width: 0
                            }

                            // Downward triangular arrow pointing at button
                            Shape {
                                id: arrowShape
                                anchors.fill: parent
                                containsMode: Shape.FillContains
                                readonly property real midX: Math.round(width / 2)

                                ShapePath {
                                    strokeWidth: 0
                                    fillColor: tipBgItem.bubbleColor

                                    startX: arrowShape.midX - 6
                                    startY: 27

                                    PathLine { x: arrowShape.midX; y: 33 }
                                    PathLine { x: arrowShape.midX + 6; y: 27 }
                                    PathLine { x: arrowShape.midX - 6; y: 27 }
                                }
                            }
                        }
                    }

                    onClicked: {
                        if (ListView.view && ListView.view.model && typeof ListView.view.model.trigger === "function") {
                            var aId = (actBtn.modelData.id || actBtn.modelData.actionId || "").toString();
                            ListView.view.model.trigger(delegateRoot.index, aId, actBtn.modelData.actionArgument || null);
                            if (typeof root !== "undefined" && root && typeof root.closeAnimated === "function") {
                                root.closeAnimated();
                            }
                        }
                    }
                }
            }
        }

        // Category Tag / Badge (when not showing action buttons)
        Rectangle {
            id: groupBadge
            Layout.alignment: Qt.AlignVCenter
            visible: !actionsRow.visible && badgeLabel.text.length > 0
            radius: 4
            color: Qt.rgba(1, 1, 1, 0.08)
            implicitWidth: badgeLabel.implicitWidth + 12
            implicitHeight: badgeLabel.implicitHeight + 6

            QQC2.Label {
                id: badgeLabel
                anchors.centerIn: parent
                text: {
                    if (delegateRoot.isShellCommand) {
                        return delegateRoot.i18n("Command line");
                    }
                    if (typeof delegateRoot.model !== "undefined" && delegateRoot.model && delegateRoot.model.group) {
                        return delegateRoot.model.group.toString();
                    }
                    return "";
                }
                font.pointSize: 8
                font.weight: Font.Normal
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.5)
            }
        }
    }
}

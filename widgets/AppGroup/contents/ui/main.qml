/*
 * SPDX-FileCopyrightText: 2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import "i18n.js" as I18n

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    Layout.preferredWidth: 90
    Layout.preferredHeight: 100
    Layout.minimumWidth: 68
    Layout.minimumHeight: 84

    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1.0
    function snap(val) {
        return Math.round(val * dpr) / dpr;
    }

    readonly property string currentPreset: (Plasmoid.configuration && Plasmoid.configuration.presetType) ? Plasmoid.configuration.presetType : "productivity"
    property string customTitle: (Plasmoid.configuration && Plasmoid.configuration.folderTitle) ? Plasmoid.configuration.folderTitle : ""
    readonly property string folderName: customTitle.length > 0 ? customTitle : getPresetTitle(currentPreset)

    property var appList: []
    property var allSystemApps: []
    property bool editingTitle: false
    property bool editMode: false
    property bool addingMode: false
    property string searchQuery: ""

    function getPresetTitle(p) {
        switch (p) {
        case "productivity":
            return I18n.t("Productivity");
        case "multimedia":
            return I18n.t("Multimedia");
        case "system":
        default:
            return I18n.t("System");
        }
    }

    function getPresetApps(p) {
        switch (p) {
        case "multimedia":
            return [
                { name: "VLC", icon: "vlc", url: "", exec: "vlc" },
                { name: "Spotify", icon: "spotify", url: "", exec: "spotify" },
                { name: "Elisa", icon: "elisa", url: "", exec: "elisa" }
            ];
        case "productivity":
        case "system":
        default:
            return [
                { name: I18n.t("Files"), icon: "system-file-manager", url: "", exec: "dolphin" },
                { name: "Terminal", icon: "utilities-terminal", url: "", exec: "konsole" },
                { name: "Discover", icon: "plasmadiscover", url: "", exec: "plasma-discover" },
                { name: I18n.t("Settings"), icon: "preferences-system", url: "", exec: "systemsettings" }
            ];
        }
    }

    function loadApps() {
        var raw = (Plasmoid.configuration && Plasmoid.configuration.appsJson) ? Plasmoid.configuration.appsJson : "";
        if (raw && raw.length >= 2) {
            try {
                var parsed = JSON.parse(raw);
                if (Array.isArray(parsed)) {
                    root.appList = parsed;
                    return;
                }
            } catch (e) {}
        }
        root.appList = getPresetApps(currentPreset);
    }

    function saveApps(newList) {
        root.appList = newList.slice();
        if (Plasmoid.configuration) {
            Plasmoid.configuration.appsJson = JSON.stringify(root.appList);
        }
    }

    function saveTitle(newTitle) {
        var trimmed = (newTitle || "").trim();
        if (trimmed.length > 0) {
            root.customTitle = trimmed;
            if (Plasmoid.configuration) {
                Plasmoid.configuration.folderTitle = trimmed;
            }
        }
        root.editingTitle = false;
    }

    function removeAppAt(idx) {
        if (idx < 0 || idx >= root.appList.length) return;
        var copy = root.appList.slice();
        copy.splice(idx, 1);
        saveApps(copy);
    }

    function hasApp(appObj) {
        if (!appObj) return false;
        for (var i = 0; i < root.appList.length; i++) {
            if (root.appList[i].name === appObj.name) return true;
        }
        return false;
    }

    function toggleAppInFolder(appObj) {
        if (!appObj) return;
        var copy = root.appList.slice();
        for (var i = 0; i < copy.length; i++) {
            if (copy[i].name === appObj.name) {
                copy.splice(i, 1);
                saveApps(copy);
                return;
            }
        }
        copy.push({
            name: appObj.name,
            icon: appObj.icon,
            url: appObj.url || "",
            exec: appObj.exec || ""
        });
        saveApps(copy);
    }

    Component.onCompleted: {
        root.loadApps();
    }

    Connections {
        target: Plasmoid.configuration
        function onAppsJsonChanged() {
            root.loadApps();
        }
        function onPresetTypeChanged() {
            if (!Plasmoid.configuration.appsJson || Plasmoid.configuration.appsJson.length === 0) {
                root.loadApps();
            }
        }
        function onFolderTitleChanged() {
            if (Plasmoid.configuration.folderTitle) {
                root.customTitle = Plasmoid.configuration.folderTitle;
            }
        }
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
        }
        function exec(cmd) {
            var fullCmd = "nohup sh -c " + JSON.stringify(cmd) + " </dev/null >/dev/null 2>&1 & # " + Date.now();
            connectSource(fullCmd);
        }
    }

    Plasma5Support.DataSource {
        id: appScanner
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            var out = data["stdout"] || "";
            if (out.length > 0) {
                try {
                    var parsed = JSON.parse(out);
                    if (Array.isArray(parsed)) {
                        root.allSystemApps = parsed;
                    }
                } catch (e) {}
            }
            disconnectSource(sourceName);
        }
    }

    function fetchSystemApps() {
        var rawUrl = Qt.resolvedUrl("list_apps.py").toString();
        var scriptPath = decodeURIComponent(rawUrl.replace(/^file:\/\//, ""));
        appScanner.connectSource("python3 \"" + scriptPath + "\" # " + Date.now());
    }

    function launchApp(item) {
        if (!item) return;
        if (item.url && (item.url.indexOf("http://") === 0 || item.url.indexOf("https://") === 0)) {
            Qt.openUrlExternally(item.url);
            return;
        }
        if (item.exec && item.exec.length > 0) {
            var bin = item.exec.split(" ")[0].replace(/"/g, "");
            var runCmd = "if command -v " + bin + " >/dev/null 2>&1 || [ -x \"" + bin + "\" ]; then " + item.exec + "; elif [ -n \"" + (item.url || "") + "\" ]; then xdg-open \"" + (item.url || "") + "\"; else " + item.exec + "; fi";
            executable.exec(runCmd);
        } else if (item.url && item.url.length > 0) {
            Qt.openUrlExternally(item.url);
        }
    }

    // ====================================================================
    // FRONT DESKTOP WIDGET: Circular Pixel Folder Disc & Mini Preview
    // ====================================================================
    fullRepresentation: Item {
        id: iconRoot
        Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
        anchors.fill: parent

        readonly property real baseSize: Math.min(width, height)
        readonly property int previewCount: Math.min(4, root.appList.length)
        readonly property real discSize: root.snap(Math.min(50, baseSize * (50.0 / 90.0)))

        Item {
            id: desktopFolderContainer
            anchors.fill: parent
            opacity: folderPopup.visible ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

            Item {
                id: folderDisc
                width: iconRoot.discSize
                height: iconRoot.discSize
                anchors.top: parent.top
                anchors.topMargin: Kirigami.Units.smallSpacing * 2
                anchors.horizontalCenter: parent.horizontalCenter

                scale: folderTap.pressed ? 0.94 : (folderPopup.visible ? 0.95 : 1.0)
                Behavior on scale { NumberAnimation { duration: folderTap.pressed ? 80 : 130; easing.type: Easing.OutQuad } }

                // Circular translucent backing adapting to Plasma theme (dark/light)
                Rectangle {
                    id: folderCircle
                    anchors.fill: parent
                    radius: width / 2
                    color: {
                        var alpha = folderHover.hovered ? 0.90 : 0.82;
                        var bg = Kirigami.Theme.backgroundColor;
                        return Qt.rgba(bg.r, bg.g, bg.b, alpha);
                    }
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    scale: folderTap.pressed ? 0.94 : (folderHover.hovered ? 1.08 : 1.0)
                    transformOrigin: Item.Center
                    Behavior on scale {
                        NumberAnimation { duration: folderTap.pressed ? 80 : 150; easing.type: Easing.OutQuad }
                    }
                }

                // Dynamic Mini Icons inside the Folder Preview
                Repeater {
                    model: root.appList.slice(0, 4)

                    Item {
                        id: miniIconDelegate
                        required property int index
                        required property var modelData

                        // Sized proportionally to disc: 18.4 dp at base 50 dp (23 px at 125% DPI)
                        readonly property real miniSize: root.snap(folderDisc.width * (18.4 / 50.0))
                        width: miniSize
                        height: miniSize

                        x: {
                            var s = folderDisc.width / 50.0;
                            var cnt = iconRoot.previewCount;
                            if (cnt === 1) return root.snap(((50 - 18.4) / 2.0) * s);
                            if (cnt === 2) return root.snap((index === 0 ? 5.5 : 26.1) * s);
                            if (cnt === 3) {
                                if (index === 0) return root.snap(((50 - 18.4) / 2.0) * s);
                                return root.snap((index === 1 ? 5.5 : 26.1) * s);
                            }
                            return root.snap(((index % 2 === 0) ? 5.5 : 26.1) * s);
                        }
                        y: {
                            var s = folderDisc.width / 50.0;
                            var cnt = iconRoot.previewCount;
                            if (cnt <= 2) return root.snap(((50 - 18.4) / 2.0) * s);
                            if (cnt === 3) {
                                return root.snap((index === 0 ? 5.0 : 26.5) * s);
                            }
                            return root.snap(((index < 2) ? 5.5 : 26.1) * s);
                        }

                        Kirigami.Icon {
                            anchors.fill: parent
                            source: (miniIconDelegate.modelData && miniIconDelegate.modelData.icon) || "application-x-executable"
                            smooth: true
                        }
                    }
                }

                // Placeholder icon when folder is empty
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: root.snap(folderDisc.width * (24.0 / 50.0))
                    height: width
                    visible: root.appList.length === 0
                    source: "folder"
                }

                HoverHandler {
                    id: folderHover
                }

                TapHandler {
                    id: folderTap
                    onTapped: {
                        folderPopup.togglePopup();
                    }
                }
            }

            // Desktop Folder Label
            Text {
                id: titleText
                anchors.top: folderDisc.bottom
                anchors.topMargin: Kirigami.Units.smallSpacing
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(implicitWidth + 6, iconRoot.width + 12)
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: root.folderName
                font.family: "Google Sans Flex"
                font.pixelSize: root.snap(11)
                font.weight: Font.Medium
                color: "#FFFFFF"
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.5)
            }
        }

        // ====================================================================
        // OPENED PIXEL FOLDER POPUP (Modular Popup Component)
        // ====================================================================
        FolderPopup {
            id: folderPopup
            rootApplet: root
            folderDisc: folderDisc
        }
    }
}

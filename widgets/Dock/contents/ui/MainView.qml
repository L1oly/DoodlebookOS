/*
 * SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-FileCopyrightText: 2022 Friedrich Schriewer <friedrich.schriewer@gmx.net>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Item {
  id: main
  property bool searching: (searchBar.textField.text != "")

  readonly property var plasmoidConfig: (typeof root !== "undefined" && root && root.plasmoidConfiguration) ? root.plasmoidConfiguration : (typeof Plasmoid !== "undefined" ? Plasmoid.configuration : null)
  readonly property bool usePlasmaTheme: Boolean(!plasmoidConfig || plasmoidConfig.usePlasmaTheme !== false)

  readonly property color baseBgColor: Kirigami.Theme.backgroundColor
  readonly property color currentBgColor: Qt.rgba(baseBgColor.r, baseBgColor.g, baseBgColor.b, 0.85)
  readonly property bool isDarkTheme: Kirigami.Theme.textColor.r > 0.5 || Kirigami.Theme.textColor.g > 0.5 || Kirigami.Theme.textColor.b > 0.5
  readonly property color textColor: Kirigami.Theme.textColor
  readonly property string textFont: (usePlasmaTheme || (plasmoidConfig && plasmoidConfig.useSystemFontSettings)) ? (Kirigami.Theme.defaultFont.family || Kirigami.Theme.defaultFont) : ((plasmoidConfig && plasmoidConfig.fontFamily) || "Google Sans Flex")
  readonly property real textSize: (usePlasmaTheme || (plasmoidConfig && plasmoidConfig.useSystemFontSettings)) ? (Kirigami.Theme.defaultFont.pointSize || 10) : ((plasmoidConfig && plasmoidConfig.fontSize) || 11)
  readonly property color bgColor: currentBgColor

  property color contrastBgColor: isDarkTheme ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)

  property alias searchBar: searchBar
  property int itemSpacing: 8

  function reset(){
    if (searchBar.textField.text !== "") {
      searchBar.textField.clear();
    }
    searchBar.textField.forceActiveFocus();
    if (!stack.currentItem || !stack.currentItem.isCombinedAppsView) {
      stack.replace(pinnedAppsComponent, StackView.Immediate);
    } else if (stack.currentItem.viewItem) {
      stack.currentItem.viewItem.positionViewAtBeginning();
    }
  }

  function setQuery(queryText) {
    var q = queryText || "";
    searchBar.textField.text = q;
    searchBar.textField.cursorPosition = q.length;
    searchBar.textField.forceActiveFocus(Qt.ShortcutFocusReason);
  }

  function findAppByNamePrefix(prefix) {
    if (!prefix || prefix.length === 0) return "";
    var lowerPrefix = prefix.toLowerCase().trim();

    if (typeof globalFavorites !== "undefined" && globalFavorites && globalFavorites.count) {
      for (var f = 0; f < globalFavorites.count; f++) {
        var favIdx = globalFavorites.index(f, 0);
        var favName = (globalFavorites.data(favIdx, Qt.DisplayRole) || "").toString();
        if (favName.toLowerCase().indexOf(lowerPrefix) === 0) {
          return favName;
        }
      }
    }

    if (typeof rootModel !== "undefined" && rootModel && rootModel.count > 2) {
      var allAppsModel = rootModel.modelForRow(2);
      if (allAppsModel && allAppsModel.count) {
        for (var a = 0; a < allAppsModel.count; a++) {
          var appIdx = allAppsModel.index(a, 0);
          var appName = (allAppsModel.data(appIdx, Qt.DisplayRole) || "").toString();
          if (appName.toLowerCase().indexOf(lowerPrefix) === 0) {
            return appName;
          }
        }
      }
    }
    return "";
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: itemSpacing

    // Search Bar
    SearchBar {
      id: searchBar
      Layout.fillWidth: true
      Layout.preferredHeight: 50
      Layout.maximumHeight: Layout.preferredHeight
      Layout.alignment: Qt.AlignTop
      Layout.topMargin: 20
      Layout.bottomMargin: 8
      Keys.priority: Keys.AfterItem
      Keys.forwardTo: stack.currentItem.viewItem
    }

    StackView {
      id: stack
      initialItem: pinnedAppsComponent
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.minimumHeight: 100
      replaceEnter: null
      replaceExit: null
      pushEnter: null
      pushExit: null
      popEnter: null
      popExit: null
      Keys.priority: Keys.AfterItem
      Keys.forwardTo: searchBar.textField
    }

    Component {
      id: pinnedAppsComponent
      CombinedAppsView {
        id: pinnedApps
      }
    }

    Component {
      id: searchComponent
      RunnerList {
        id: runnerList
        model: runnerModel.count ? runnerModel.modelForRow(0) : null
      }
    }

  }

  onSearchingChanged: {
    if (typeof root !== "undefined" && root && root.launcherContextMenu && root.launcherContextMenu.visible) {
      root.launcherContextMenu.close();
    }
    if (searching) {
      stack.replace(searchComponent, StackView.Immediate);
    } else { 
      stack.replace(pinnedAppsComponent, StackView.Immediate);
    }
  }
}

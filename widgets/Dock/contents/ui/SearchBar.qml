/*
 * SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import "i18n.js" as I18n

Rectangle {
    id: searchBarRoot

    function i18n(k, a1, a2) { return I18n.t(k, a1, a2); }

    radius: height / 2
    color: main.contrastBgColor

    property alias textField: textField

    readonly property string predictedName: {
        var q = textField.text ? textField.text.trim() : "";
        if (q.length === 0) return "";

        // 1. Try RunnerList topResultName
        if (typeof stack !== "undefined" && stack && stack.currentItem) {
            if (typeof stack.currentItem.topResultName === "string" && stack.currentItem.topResultName.length > 0) {
                return stack.currentItem.topResultName;
            }
            if (stack.currentItem.viewItem) {
                var view = stack.currentItem.viewItem;
                if (view.count > 0 && view.model) {
                    var targetIdx = (view.currentIndex >= 0 && view.currentIndex < view.count) ? view.currentIndex : 0;
                    var idx = view.model.index(targetIdx, 0);
                    var val = view.model.data(idx, Qt.DisplayRole);
                    if (val) return val.toString();
                }
            }
        }

        // 2. Instant fallback from installed apps / favorites
        if (typeof main !== "undefined" && main && typeof main.findAppByNamePrefix === "function") {
            var fb = main.findAppByNamePrefix(q);
            if (fb && fb.length > 0) return fb;
        }

        return "";
    }

    readonly property string ghostSuffix: {
        var query = textField.text;
        if (!query || query.length === 0) return "";
        var name = predictedName;
        if (!name || name.length === 0) return "";

        var lowerQuery = query.toLowerCase().trim();
        var lowerName = name.toLowerCase().trim();
        if (lowerQuery.length === 0) return "";

        var actionText = " - " + i18n("launch");

        // Only show ghost suffix when the name starts with the typed query (clean inline autocomplete)
        if (lowerName.indexOf(lowerQuery) === 0) {
            var remainder = name.substring(query.length);
            return remainder + actionText;
        }

        return "";
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 8

        // Text input field
        TextField {
            id: textField
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            font.family: main.textFont
            font.pointSize: main.textSize + 2
            color: main.textColor
            verticalAlignment: TextInput.AlignVCenter

            placeholderText: i18n("Search web and more")
            placeholderTextColor: Qt.rgba(main.textColor.r, main.textColor.g, main.textColor.b, 0.55)

            background: Item {}
            focus: true

            Text {
                id: ghostTextLabel
                anchors.baseline: textField.baseline
                anchors.left: parent.left
                anchors.leftMargin: (textField.leftPadding || 0) - (textField.contentX || 0)
                anchors.right: parent.right
                anchors.rightMargin: textField.rightPadding || 0
                font: textField.font
                textFormat: Text.RichText
                clip: true
                text: {
                    if (!textField.text || !searchBarRoot.ghostSuffix) return "";
                    function escapeHtml(str) {
                        return str.toString()
                                  .replace(/&/g, "&amp;")
                                  .replace(/</g, "&lt;")
                                  .replace(/>/g, "&gt;")
                                  .replace(/"/g, "&quot;");
                    }
                    var ghostColor = Qt.rgba(main.textColor.r, main.textColor.g, main.textColor.b, 0.38);
                    return "<span style='white-space: pre; color: transparent;'>" + escapeHtml(textField.text) + "</span>"
                         + "<span style='white-space: pre; color: " + ghostColor + ";'>" + escapeHtml(searchBarRoot.ghostSuffix) + "</span>";
                }
                visible: textField.text.length > 0 && searchBarRoot.ghostSuffix.length > 0
                elide: Text.ElideRight
                z: -1
                enabled: false
            }

            onTextChanged: {
                textField.forceActiveFocus(Qt.ShortcutFocusReason)
                runnerModel.query = text;
            }

            function triggerSelectedResult(shiftPressed) {
                if (stack.currentItem) {
                    var view = stack.currentItem.viewItem;
                    if (view && view.count > 0) {
                        if (typeof stack.currentItem.footerSelected !== "undefined" && stack.currentItem.footerSelected) {
                            if (typeof stack.currentItem.openWebOrUrl === "function") {
                                stack.currentItem.openWebOrUrl(textField.text);
                                return;
                            }
                        }
                        var targetIdx = (view.currentIndex >= 0 && view.currentIndex < view.count) ? view.currentIndex : 0;
                        if (view.currentItem) {
                            if (shiftPressed && typeof view.currentItem.runFirstAction === "function") {
                                view.currentItem.runFirstAction();
                                return;
                            } else if (typeof view.currentItem.runPrimary === "function") {
                                view.currentItem.runPrimary();
                                return;
                            } else if (typeof view.currentItem.trigger === "function") {
                                view.currentItem.trigger();
                                return;
                            }
                        }
                        if (view.model && typeof view.model.trigger === "function") {
                            view.model.trigger(targetIdx, "", null);
                            if (typeof root !== "undefined" && root && typeof root.closeAnimated === "function") {
                                root.closeAnimated();
                            }
                        }
                    } else if (typeof stack.currentItem.openWebOrUrl === "function") {
                        stack.currentItem.openWebOrUrl(textField.text);
                    }
                }
            }

            onAccepted: {
                triggerSelectedResult(false);
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    event.accepted = true;
                    if (searching) {
                        clear();
                    } else {
                        root.closeAnimated();
                    }
                } else if ((event.key === Qt.Key_Tab || event.key === Qt.Key_Right) && searchBarRoot.ghostSuffix.length > 0) {
                    if (cursorPosition === text.length && searchBarRoot.predictedName.length > 0) {
                        text = searchBarRoot.predictedName;
                        cursorPosition = text.length;
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_Down) {
                    if (stack.currentItem && stack.currentItem.viewItem) {
                        stack.currentItem.viewItem.forceActiveFocus(Qt.TabFocusReason);
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    event.accepted = true;
                    var isShift = Boolean(event.modifiers & Qt.ShiftModifier);
                    triggerSelectedResult(isShift);
                }
            }
        }
    }
}

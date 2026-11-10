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

    readonly property color accent: Kirigami.Theme.highlightColor
    readonly property color bgColor: Kirigami.Theme.backgroundColor
    readonly property bool isDarkMode: (Kirigami.Theme.backgroundColor.r * 0.299 + Kirigami.Theme.backgroundColor.g * 0.587 + Kirigami.Theme.backgroundColor.b * 0.114 < 0.5)
    readonly property color textColor: isDarkMode
        ? Qt.tint("#ffffff", Qt.rgba(accent.r, accent.g, accent.b, 0.35))
        : Qt.tint(Kirigami.Theme.textColor, Qt.rgba(accent.r, accent.g, accent.b, 0.20))

    property string cityName: Plasmoid.configuration.cityName ? Plasmoid.configuration.cityName.trim() : ""
    property string temperature: "--"
    property int weatherCode: 1
    property bool isDay: true

    function getWeatherIconSource(code, isDaytime) {
        var fileName = isDaytime ? "partly_cloudy.svg" : "partly_cloudy_night.svg";

        if (code === 0) {
            fileName = isDaytime ? "sunny.svg" : "clear_night.svg";
        } else if (code === 1) {
            fileName = isDaytime ? "mostly_sunny.svg" : "mostly_clear_night.svg";
        } else if (code === 2) {
            fileName = isDaytime ? "partly_cloudy.svg" : "partly_cloudy_night.svg";
        } else if (code === 3) {
            fileName = isDaytime ? "cloudy.svg" : "mostly_cloudy_night.svg";
        } else if (code === 45 || code === 48) {
            fileName = "windy.svg";
        } else if ((code >= 51 && code <= 57) || code === 61 || code === 80) {
            fileName = "drizzle.svg";
        } else if (code >= 63 && code <= 65 || code === 81 || code === 82) {
            fileName = "heavy_rain.svg";
        } else if (code >= 71 && code <= 77) {
            fileName = "heavy_snow.svg";
        } else if (code >= 85 && code <= 86) {
            fileName = "snow_showers.svg";
        } else if (code >= 95 && code <= 99) {
            fileName = (code >= 96) ? "strong_thunderstorms.svg" : "thunderstorms.svg";
        }

        var folder = root.isDarkMode ? "dark" : "light";
        return Qt.resolvedUrl("icons/" + folder + "/" + fileName);
    }

    function fetchByIpFallback() {
        var xhrIp2 = new XMLHttpRequest();
        xhrIp2.open("GET", "https://ipapi.co/json/", true);
        xhrIp2.onreadystatechange = function() {
            if (xhrIp2.readyState === XMLHttpRequest.DONE) {
                if (xhrIp2.status === 200) {
                    try {
                        var ipRes2 = JSON.parse(xhrIp2.responseText);
                        if (typeof ipRes2.latitude === "number" && typeof ipRes2.longitude === "number") {
                            loadCurrentWeather(ipRes2.latitude, ipRes2.longitude);
                            return;
                        }
                    } catch (e) {}
                }
                loadCurrentWeather(52.2297, 21.0122);
            }
        };
        xhrIp2.send();
    }

    function fetchWeather() {
        var rawCity = root.cityName.trim();
        if (!rawCity) {
            var xhrIp = new XMLHttpRequest();
            xhrIp.open("GET", "https://ipwho.is/", true);
            xhrIp.onreadystatechange = function() {
                if (xhrIp.readyState === XMLHttpRequest.DONE) {
                    if (xhrIp.status === 200) {
                        try {
                            var ipRes = JSON.parse(xhrIp.responseText);
                            if (ipRes && ipRes.success !== false && typeof ipRes.latitude === "number" && typeof ipRes.longitude === "number") {
                                loadCurrentWeather(ipRes.latitude, ipRes.longitude);
                                return;
                            }
                        } catch (e) {}
                    }
                    fetchByIpFallback();
                }
            };
            xhrIp.send();
            return;
        }

        var query = encodeURIComponent(rawCity);
        var geoUrl = "https://geocoding-api.open-meteo.com/v1/search?name=" + query + "&count=1&language=en&format=json";
        var xhrGeo = new XMLHttpRequest();
        xhrGeo.open("GET", geoUrl, true);
        xhrGeo.onreadystatechange = function() {
            if (xhrGeo.readyState === XMLHttpRequest.DONE && xhrGeo.status === 200) {
                try {
                    var geoRes = JSON.parse(xhrGeo.responseText);
                    if (geoRes.results && geoRes.results.length > 0) {
                        var loc = geoRes.results[0];
                        loadCurrentWeather(loc.latitude, loc.longitude);
                    }
                } catch (e) {}
            }
        };
        xhrGeo.send();
    }

    function loadCurrentWeather(lat, lon) {
        var weatherUrl = "https://api.open-meteo.com/v1/forecast?latitude=" + lat +
                         "&longitude=" + lon +
                         "&current=temperature_2m,is_day,weather_code" +
                         "&timezone=auto";

        var xhr = new XMLHttpRequest();
        xhr.open("GET", weatherUrl, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    if (data && data.current) {
                        root.temperature = Math.round(data.current.temperature_2m).toString();
                        root.weatherCode = data.current.weather_code;
                        root.isDay = (data.current.is_day === 1);
                    }
                } catch (e) {}
            }
        };
        xhr.send();
    }

    Component.onCompleted: fetchWeather()

    Connections {
        target: Plasmoid.configuration
        function onCityNameChanged() { root.fetchWeather(); }
    }

    // Refresh every 30 minutes
    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: root.fetchWeather()
    }


    fullRepresentation: Item {
        id: widgetRoot
        implicitWidth: 220
        implicitHeight: 220

        Item {
            id: pillContainer
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) * 0.95
            height: width

            Image {
                id: pillBackground
                anchors.fill: parent
                source: Qt.resolvedUrl("assets/pill.svg")
                sourceSize: Qt.size(parent.width, parent.height)
                fillMode: Image.PreserveAspectFit
                antialiasing: true
                smooth: true
                visible: false
            }

            MultiEffect {
                anchors.fill: pillBackground
                source: pillBackground
                colorization: 1.0
                colorizationColor: root.bgColor
            }

            Item {
                id: innerContent
                anchors.centerIn: parent
                width: parent.width * 0.72
                height: parent.height * 0.72

                Text {
                    id: tempText
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -parent.height * 0.18
                    anchors.rightMargin: parent.width * 0.04
                    text: root.temperature + "°"
                    font.pixelSize: Math.round(parent.height * 0.44)
                    font.weight: 500
                    font.family: "Google Sans Flex"
                    font.variableAxes: { "ROND": 100 }
                    color: root.textColor
                }

                Image {
                    id: weatherIcon
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: parent.height * 0.18
                    anchors.leftMargin: parent.width * 0.04
                    width: parent.width * 0.45
                    height: width
                    source: root.getWeatherIconSource(root.weatherCode, root.isDay)
                    sourceSize: Qt.size(192, 192)
                    fillMode: Image.PreserveAspectFit
                    antialiasing: true
                    smooth: true
                }
            }
        }
    }
}

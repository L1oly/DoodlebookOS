/*
    SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

.pragma library

var currentLocale = "en"; // default UI language; set to "pl" etc. to enable a translation

var dict = {
    "pl": {
        "%1:": "%1:",
        "Click the clock icon to open Date & Time settings and set a time zone.": "Kliknij ikonę zegara, aby otworzyć ustawienia daty i czasu oraz ustawić strefę czasową.",
        "Middle-click to open %1": "Kliknij środkowym przyciskiem, aby otworzyć %1",
        "Next Decade": "Następna dekada",
        "Next Month": "Następny miesiąc",
        "Next Year": "Następny rok",
        "Previous Decade": "Poprzednia dekada",
        "Previous Month": "Poprzedni miesiąc",
        "Previous Year": "Poprzedni rok",
        "Time zone is not set": "Strefa czasowa nie jest ustawiona",
        "Today is %1": "Dzisiaj jest %1"
    }
};

function t(key, a1, a2) {
    var loc = currentLocale || "en";
    var val = (dict[loc] && dict[loc][key] !== undefined) ? dict[loc][key] : key;
    if (a1 !== undefined && typeof val === "string") val = val.replace("%1", a1);
    if (a2 !== undefined && typeof val === "string") val = val.replace("%2", a2);
    return val;
}

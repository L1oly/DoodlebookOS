/*
 * SPDX-FileCopyrightText: 2024-2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

.pragma library

var currentLocale = "en"; // default UI language; set to "pl" etc. to enable a translation

var dict = {
    "pl": {
        "Always show Taskbar": "Zawsze pokazuj pasek zadań",
        "App info": "Ustawienia aplikacji",
        "Close": "Zamknij",
        "Pin to Taskbar": "Przypnij do paska zadań",
        "Pin to Dock": "Przypnij do paska zadań",
        "Unpin from Dock": "Odepnij z paska zadań",
        "Remove from Taskbar": "Usuń z paska zadań",
        "Search web and more": "Szukaj w sieci i innych miejscach",
        "Open website: ": "Otwórz stronę: ",
        "Search Google for: ": "Szukaj w Google: ",
        "Open in browser": "Otwórz w przeglądarce",
        "Web search": "Wyszukiwanie w internecie",
        "Copied to clipboard: ": "Skopiowano do schowka: ",
        "Run in terminal window (Shift+Enter: in background)": "Uruchom w oknie terminala (Shift+Enter: w tle)",
        "Command line": "Wiersz poleceń",
        "launch": "uruchom",
        "Hide": "Ukryj",
        "Un-hide": "Odkryj",
        "Phone": "Telefon",
        "No connected phone": "Brak połączonego telefonu",
        "Ring": "Zadzwoń",
        "Ringing…": "Dzwoni...",
        "Files": "Pliki",
        "Send": "Wyślij",
        "Do not disturb": "Nie przeszkadzać",
        "Notifications": "Powiadomienia",
        "Clear all": "Wyczyść wszystko",
        "All caught up": "Wszystko przeczytane",
        "Reply": "Odpowiedz"
    }
};

function t(key, a1, a2) {
    var loc = currentLocale || "en";
    var val = (dict[loc] && dict[loc][key] !== undefined) ? dict[loc][key] : key;
    if (a1 !== undefined && typeof val === "string") val = val.replace("%1", a1);
    if (a2 !== undefined && typeof val === "string") val = val.replace("%2", a2);
    return val;
}

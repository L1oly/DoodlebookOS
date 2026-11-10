.pragma library

var currentLocale = "en"; // default UI language; set to "pl" etc. to enable a translation

var dict = {
    "pl": {
        "All settings…": "Wszystkie ustawienia…",
        "Copy": "Kopiuj",
        "Display settings": "Ustawienia wyświetlacza",
        "Lock screen": "Zablokuj ekran",
        "More settings": "Więcej ustawień",
        "More system options…": "Więcej opcji systemowych…",
        "Move to Trash": "Przenieś do kosza",
        "New folder": "Nowy folder",
        "Open": "Otwórz",
        "Open in terminal": "Otwórz w terminalu",
        "Remove": "Usuń",
        "Rename": "Zmień nazwę",
        "Wallpaper": "Tapeta",
        "Widgets": "Widżety"
    }
};

function t(key, a1, a2) {
    var loc = currentLocale || "en";
    var val = (dict[loc] && dict[loc][key] !== undefined) ? dict[loc][key] : key;
    if (a1 !== undefined && typeof val === "string") val = val.replace("%1", a1);
    if (a2 !== undefined && typeof val === "string") val = val.replace("%2", a2);
    return val;
}

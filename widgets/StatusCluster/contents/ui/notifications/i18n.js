.pragma library

var translations = {
    "pl": {
        "now": "teraz",
        "min": "min",
        "h": "godz.",
        "d": "dni",
        "Silent": "Ciche",
        "System": "System",
        "No notifications": "Brak powiadomień",
        "Clear all": "Wyczyść wszystko",
        "Reply…": "Napisz odpowiedź…"
    }
};

function getSystemLanguage() {
    // Default UI language is English; return "pl" (or another added translation) to enable it.
    return "en";
}

function t(key) {
    var lang = getSystemLanguage();
    if (lang === "pl" && translations["pl"] && translations["pl"][key]) {
        return translations["pl"][key];
    }
    return key;
}

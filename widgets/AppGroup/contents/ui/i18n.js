.pragma library

var currentLocale = "en"; // default UI language; set to "pl" etc. to enable a translation

var translations = {
    "pl": {
        "Multimedia": "Multimedia",
        "Settings": "Ustawienia",
        "Productivity": "Produktywność",
        "System": "System",
        "Files": "Pliki",
        "Terminal": "Terminal",
        "Discover": "Discover",
        "Add apps": "Dodaj aplikacje",
        "Add to:": "Dodaj do:",
        "Search apps...": "Szukaj aplikacji...",
        "Folder is empty": "Folder jest pusty"
    },
    "en": {}
};

function t(key) {
    var lang = currentLocale;
    if (translations[lang] && translations[lang][key]) {
        return translations[lang][key];
    }
    return key;
}

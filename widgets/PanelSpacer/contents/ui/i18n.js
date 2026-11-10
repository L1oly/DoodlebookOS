.pragma library

var currentLocale = "en"; // default UI language; set to "pl" etc. to enable a translation

var dict = {
    "pl": {
        "Always show Taskbar": "Zawsze pokazuj pasek zadań"
    }
};

function t(key) {
    if (currentLocale === "pl" && dict["pl"] && dict["pl"][key]) {
        return dict["pl"][key];
    }
    return key;
}

.pragma library

var currentLocale = "en"; // default UI language; set to "pl" etc. to enable a translation

var dict = {
    "pl": {
        "No media playing": "Brak odtwarzanych multimediów",
        "Paused": "Wstrzymano",
        "Play": "Odtwórz",
        "Sleep": "Wstrzymaj"
    }
};

function t(key, a1, a2) {
    var loc = currentLocale || "en";
    var val = (dict[loc] && dict[loc][key] !== undefined) ? dict[loc][key] : key;
    if (a1 !== undefined && typeof val === "string") val = val.replace("%1", a1);
    if (a2 !== undefined && typeof val === "string") val = val.replace("%2", a2);
    return val;
}

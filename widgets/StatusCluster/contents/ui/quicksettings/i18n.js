.pragma library

var currentLocale = "en"; // default UI language; set to "pl" etc. to enable a translation

var dict = {
    "pl": {
        "%1% (%2)": "%1% (%2)",
        "AC Power": "Zasilanie sieciowe (AC)",
        "Area capture": "Wycinek ekranu",
        "Available": "Dostępna",
        "Available devices": "Dostępne urządzenia",
        "Available networks": "Dostępne sieci",
        "Battery Power": "Zasilanie z wewnętrznego akumulatora",
        "Battery Saver": "Oszczędzanie baterii",
        "Battery\nsaver": "Oszczędzanie\nbaterii",
        "Bluetooth": "Bluetooth",
        "Bluetooth is turned off": "Bluetooth jest wyłączony",
        "Cancel": "Anuluj",
        "Charging": "Ładowanie",
        "Connect": "Połącz",
        "Connected": "Połączono",
        "Connected to AC": "Podłączona do sieci",
        "Connected to power": "Podłączono do zasilania",
        "Connected to power source": "Podłączono do źródła zasilania",
        "Connectivity": "Łączność",
        "Dark theme": "Ciemny motyw",
        "Dark\ntheme": "Ciemny\nmotyw",
        "Desktop computer or external power supply": "Komputer stacjonarny lub zasilacz zewnętrzny",
        "Disconnect": "Rozłącz",
        "Do not disturb": "Nie przeszkadzać",
        "Do not\ndisturb": "Nie\nprzeszkadzać",
        "Edit tiles": "Edytuj kafelki",
        "Enter password for %1:": "Wprowadź hasło dla %1:",
        "Fully charged": "W pełni naładowana",
        "Internet": "Internet",
        "KDE Connect": "KDE Connect",
        "Keyboard": "Klawiatura",
        "Log out": "Wyloguj",
        "Microphone access": "Dostęp do mikrofonu",
        "Microphone\naccess": "Dostęp do\nmikrofonu",
        "More Bluetooth settings...": "Więcej ustawień Bluetooth...",
        "More Wi-Fi settings": "Więcej ustawień Wi-Fi",
        "More power settings...": "Więcej ustawień zasilania...",
        "Muted": "Wyciszony",
        "Network password": "Hasło sieci",
        "Not connected": "Nie połączono",
        "Off": "Wył.",
        "On": "Wł.",
        "On battery": "Praca na baterii",
        "Power & battery": "Zasilanie i bateria",
        "Power &\nbattery": "Zasilanie i\nbateria",
        "Power off": "Wyłącz",
        "Quick Share": "Udostępnianie w pobliżu",
        "Quick\nShare": "Quick\nShare",
        "Remove": "Usuń",
        "Reset": "Zresetuj",
        "Restart": "Uruchom ponownie",
        "Screenshot": "Zrzut ekranu",
        "See all": "Zobacz wszystkie",
        "Shut down": "Wyłącz",
        "Sign out": "Wyloguj",
        "System & power": "System i zasilanie",
        "Tap a device to connect": "Dotknij urządzenia, aby połączyć",
        "Tap a network to connect": "Dotknij sieci, aby połączyć",
        "Tools": "Narzędzia",
        "Turn on Bluetooth": "Włącz Bluetooth",
        "Turn on Bluetooth to connect to devices.": "Włącz Bluetooth, aby połączyć się z urządzeniami.",
        "Turn on Wi-Fi": "Włącz Wi-Fi",
        "Turn on Wi-Fi to see available networks.": "Włącz Wi-Fi, aby zobaczyć dostępne sieci.",
        "Unavailable": "Niedostępny",
        "Virtual keyboard": "Klawiatura wirtualna",
        "Wi-Fi": "Wi-Fi",
        "Wi-Fi is off": "Wi-Fi jest wyłączone"
    }
};

function t(key, a1, a2) {
    var loc = currentLocale || "en";
    var val = (dict[loc] && dict[loc][key] !== undefined) ? dict[loc][key] : key;
    if (a1 !== undefined && typeof val === "string") val = val.replace("%1", a1);
    if (a2 !== undefined && typeof val === "string") val = val.replace("%2", a2);
    return val;
}

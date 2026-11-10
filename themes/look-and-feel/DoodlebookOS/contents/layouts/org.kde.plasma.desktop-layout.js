// DoodlebookOS - Official Desktop & Panel Layout for KDE Plasma 6
var plasma = getApiVersion(1);

var layout = {
    "desktops": [
        {
            "applets": [],
            "config": {
                "/": {
                    "formfactor": "0",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                }
            },
            "wallpaperPlugin": "org.kde.image"
        }
    ],
    "panels": [
        {
            "alignment": "center",
            "applets": [
                {
                    "config": {
                        "/General": {
                            "expanding": "true"
                        }
                    },
                    "plugin": "org.doodlebookos.panelspacer"
                },
                {
                    "config": {
                        "/General": {
                            "launchers": "preferred://browser,preferred://filemanager,applications:org.kde.konsole.desktop,applications:org.kde.discover.desktop,applications:systemsettings.desktop"
                        }
                    },
                    "plugin": "org.doodlebookos.dock"
                },
                {
                    "config": {
                        "/General": {
                            "expanding": "true"
                        }
                    },
                    "plugin": "org.doodlebookos.panelspacer"
                }
            ],
            "config": {
                "/": {
                    "formfactor": "2",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                }
            },
            "floating": false,
            "height": 2.56,
            "hiding": "normal",
            "lengthMode": "fill",
            "location": "bottom",
            "offset": 0,
            "opacity": "translucent"
        },
        {
            "alignment": "left",
            "applets": [
                {
                    "config": {
                        "/General": {
                            "expanding": "false"
                        }
                    },
                    "plugin": "org.doodlebookos.datetime"
                },
                {
                    "config": {
                        "/General": {
                            "expanding": "true"
                        }
                    },
                    "plugin": "org.doodlebookos.panelspacer"
                },
                {
                    "config": {},
                    "plugin": "org.doodlebookos.statuscluster"
                }
            ],
            "config": {
                "/": {
                    "formfactor": "2",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                },
                "/General": {
                    "UserBackgroundHints": "NoBackground"
                }
            },
            "floating": false,
            "height": 1.44,
            "hiding": "normal",
            "lengthMode": "fill",
            "location": "top",
            "offset": 0,
            "opacity": "translucent"
        }
    ],
    "serializationFormatVersion": "1"
};

plasma.loadSerializedLayout(layout);

// Post-load setup: global shortcut Meta for launcher & ensure attached full-width panel properties
var allPanels = panels();
for (var i = 0; i < allPanels.length; ++i) {
    var p = allPanels[i];
    p.floating = false;
    p.lengthMode = "fill";

    if (p.location === "bottom") {
        p.height = 52;
    } else if (p.location === "top") {
        p.height = 32;
        p.userBackgroundHints = 0;
    }

    var ws = p.widgets();
    for (var j = 0; j < ws.length; ++j) {
        var w = ws[j];
        if (w.type === "org.doodlebookos.dock") {
            w.globalShortcut = "Meta";
        }
    }
}

// Ensure desktop widgets (Clock, Weather, and 1 AppGroup folder) are placed on the desktop
var ds = desktops();
for (var d = 0; d < ds.length; ++d) {
    var desk = ds[d];
    var sGeom = screenGeometry(desk.screen);
    var sW = (sGeom && sGeom.width > 0) ? sGeom.width : 1920;
    var sH = (sGeom && sGeom.height > 0) ? sGeom.height : 1080;
    var topOffset = Math.round(sH * 0.05);
    var glanceX = Math.round(sW * 0.05);

    var ws = desk.widgets();
    var hasClock = false;
    var hasWeather = false;
    var existingAppGroups = 0;
    for (var k = 0; k < ws.length; ++k) {
        if (ws[k].type === "org.doodlebookos.clock") hasClock = true;
        if (ws[k].type === "org.doodlebookos.weather") hasWeather = true;
        if (ws[k].type === "org.doodlebookos.appgroup") existingAppGroups++;
    }

    if (!hasClock) {
        desk.addWidget("org.doodlebookos.clock", glanceX, topOffset + 16, 220, 220);
    }
    if (!hasWeather) {
        desk.addWidget("org.doodlebookos.weather", glanceX, topOffset + 252, 220, 220);
    }
    if (existingAppGroups === 0) {
        var colX = Math.round(sW - 130);
        var fObj = desk.addWidget("org.doodlebookos.appgroup", colX, topOffset + 16, 90, 100);
        if (fObj) {
            fObj.currentConfigGroup = ["General"];
            fObj.writeConfig("folderTitle", "System");
            fObj.writeConfig("appsJson", JSON.stringify([
                {"name": "Dolphin", "icon": "system-file-manager", "exec": "dolphin"},
                {"name": "Konsole", "icon": "utilities-terminal", "exec": "konsole"},
                {"name": "Discover", "icon": "plasmadiscover", "exec": "plasma-discover"},
                {"name": "System Settings", "icon": "preferences-system", "exec": "systemsettings"}
            ]));
        }
    }
}

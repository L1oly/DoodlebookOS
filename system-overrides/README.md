# DoodlebookOS — System Overrides (`system-overrides/`)

This directory contains optional system-level integrations that bridge KDE Plasma 6 services with the DoodlebookOS desktop experience.

---

## Components

1. **`krunner-bridge/` (`doodlebook-krunner-bridge.py` & `systemd/plasma-krunner.service`):**
   - Lightweight DBus service claiming `org.kde.krunner` (`/App`, `org.kde.krunner.App`).
   - Redirects global KRunner invocations (`Alt+Space`, search shortcuts, desktop search actions) directly to the DoodlebookOS Dock Launcher via DBus `PropertiesChanged` signals.
2. **`plasma/clipboard/` (`KlipperPopup.qml` & `icons/`):**
   - Material You 2-column masonry clipboard popup override (`Meta+V`) for KDE Klipper with image thumbnails, inline delete mode, and adaptive Light/Dark theme support.

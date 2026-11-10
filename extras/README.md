# DoodlebookOS — Extras & Utilities (`extras/`)

This directory contains supporting visual assets and helper scripts installed into the user environment.

---

## Contents

- **`cursors/DoodlebookOS-Cursors/`**: Custom cursor theme (`DoodlebookOS-Cursors`) inheriting fallback cursors from `breeze_cursors`.
- **`icons/DoodlebookOS/`**: Custom Material You icon theme (`DoodlebookOS`) inheriting fallback icons from `breeze`.
- **`fonts/GoogleSansFlex/`**: Variable UI font (`Google Sans Flex`, licensed under the SIL Open Font License in `OFL.txt`) used across DoodlebookOS panels, widgets, and popups.
- **`wallpapers/`**: Default high-resolution wallpapers (`DoodlebookOS_Wallpaper_DARK.png` and `DoodlebookOS_Wallpaper_LIGHT.png`).
- **`scripts/dostheme`**: CLI utility (`dostheme [dark|light|toggle|status]`) that switches the KDE color scheme, Plasma desktop theme (`DoodlebookOS_Dark` / `DoodlebookOS_Light`), default wallpaper, and top bar contrast in sync.
- **`scripts/doodlebookos-topbar-color`**: Background daemon and CLI helper that samples the active desktop wallpaper luminance under the top left (`DateTime`) and top right (`StatusCluster`) panel regions and dynamically adjusts text/icon contrast (`#ffffff` vs `#000000`).
- **`scripts/doodlebookos-topbar.service`**: User systemd service unit running `doodlebookos-topbar-color --daemon`.

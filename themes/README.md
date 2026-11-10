# DoodlebookOS — Visual Themes & Native C++ Plugins (`themes/`)

This directory contains the native C++ styles, KWin window decorations, Plasma desktop themes, color schemes, and Global Look-and-Feel package for KDE Plasma 6.

---

## Directory Structure

| Directory | Component Type | Description |
|---|---|---|
| `app-style/DoodlebookOS/` | Qt6 / KF6 KStyle Plugin (C++) | Custom application widget style (`doodlebookos6.so`) providing rounded Material You controls, menus, and surfaces. Built via `build.sh` (CMake + Ninja). |
| `window-decoration/DoodlebookOS/` | KDecoration3 Plugin (C++) | Custom KWin window decoration (`org.doodlebookos.decoration.so`) with clean titlebars, rounded corners, and Material window buttons. Built via `build.sh`. |
| `plasma-theme/DoodlebookOS_Dark/` | Plasma Desktop Theme | Dark Plasma SVG style (`DoodlebookOS_Dark`) with `32 dp` rounded dialog/popup backgrounds and transparent panel surfaces. |
| `plasma-theme/DoodlebookOS_Light/` | Plasma Desktop Theme | Light Plasma SVG style (`DoodlebookOS_Light`) without dark panel dimming. |
| `color-schemes/` | KDE Color Schemes | `DoodlebookOS_DARK.colors` and `DoodlebookOS_LIGHT.colors` semantic Material You color palettes. |
| `look-and-feel/DoodlebookOS/` | Plasma Global Theme | `org.doodlebookos.desktop` Look-and-Feel package defining the default panel/desktop layout (`org.kde.plasma.desktop-layout.js`) and KWin/Plasma defaults. |

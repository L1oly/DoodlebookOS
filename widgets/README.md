# DoodlebookOS — Plasma 6 Applets & Desktop Containment (`widgets/`)

This directory contains the 8 custom KDE Plasma 6 QML applets and desktop containment that form the DoodlebookOS user interface.

---

## Overview of Applets

| Directory | Plugin ID | Context | Role & Features |
|---|---|---|---|
| `Desktop/` | `org.kde.desktopcontainment` | Desktop Containment | Custom desktop containment with Material 3 Expressive right-click context menu, live wallpaper carousel, optical grid alignment for app folders, and simplified widget overlay (`Configure` + `Remove`). |
| `Dock/` | `org.doodlebookos.dock` | Bottom Panel (`52 dp`) | ChromeOS-style shelf dock with centered task manager, integrated KRunner-powered app/web/command launcher, and KDE Connect Phone Hub popup. |
| `DateTime/` | `org.doodlebookos.datetime` | Top Panel (`32 dp`) | Top-left date & time pill with adaptive wallpaper contrast and a clean single-column Material You monthly calendar popup. |
| `StatusCluster/` | `org.doodlebookos.statuscluster` | Top Panel (`32 dp`) | Unified top-right status cluster combining media player controls, notification center (`org.kde.plasma.notifications`), and Quick Settings drawer (Wi-Fi, Bluetooth, Dark Mode, Power Profiles, Do Not Disturb, Mic, Screenshot, Quick Share). |
| `PanelSpacer/` | `org.doodlebookos.panelspacer` | Top & Bottom Panels | Flexible panel spacer with custom taskbar context menu integration. |
| `Clock/` | `org.doodlebookos.clock` | Desktop Widget (`220×220 dp`) | Material 3 Expressive 12-sided cookie analog clock with dynamic accent tinting. |
| `Weather/` | `org.doodlebookos.weather` | Desktop Widget (`220×220 dp`) | Material You weather widget powered by Open-Meteo with automatic IP geolocation fallback and hourly/daily forecast views. |
| `AppGroup/` | `org.doodlebookos.appgroup` | Desktop Widget (`90×100 dp`) | Desktop application folder with a 2×2 mini icon preview and an expandable app grid drawer. |

---

## Scaling & Pixel-Grid Architecture

All applets follow a strict pixel-snapping architecture (`snap(val) = Math.round(val * dpr) / dpr`) across three UI contexts:

1. **Panel Elements (`DateTime`, `StatusCluster`, `Dock`):**
   - Top Bar base height: `32 dp` (rail/pill height `0.675 * effectiveHeight`, vertically centered).
   - Bottom Dock base height: `52 dp` with full-bleed panel thickness discovery.
2. **Popups & Drawers (`LauncherPopup`, `CalendarView`, `QuickSettings`):**
   - Ergonomic fixed widths in `dp` with height clamped to available screen geometry.
3. **Desktop Canvas Widgets (`Clock`, `Weather`, `AppGroup`):**
   - Responsive internal layout scaled proportionally to `Math.min(width, height)`.

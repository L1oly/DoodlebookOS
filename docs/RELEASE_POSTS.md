# DoodlebookOS — Gotowe Wpisy Premierowe (Launch Copy)

Ten dokument zawiera gotowe do skopiowania posty na dzień premiery wersji **Alpha (v0.9.0-alpha)**.

---

## 1. Reddit: r/unixporn

> **Uwaga dotycząca r/unixporn:** 
> 1. Wybierz format **Images & Video** i załącz przygotowane zrzuty ekranu 16:9 (oraz ewentualnie klip .mp4).
> 2. Zaraz po opublikowaniu posta natychmiast dodaj poniższy komentarz techniczny (Details Comment) – moderatorzy usuwają posty bez komentarza ze szczegółami.

### Tytuł posta:
```text
[Plasma] DoodlebookOS — A complete Material 3 Expressive desktop suite crafted natively for KDE Plasma 6 & Wayland
```

### Pierwszy komentarz (Details Comment — wklej od razu po publikacji):
```markdown
### DoodlebookOS (v0.9 Alpha)

A complete Material 3 Expressive desktop environment suite crafted natively for **KDE Plasma 6 on Wayland**, bringing the unified modern Android PC / Googlebook desktop experience to Linux.

- **OS / Distro:** Fedora 41 (tested on Arch & openSUSE)
- **Desktop Environment:** KDE Plasma 6.2+
- **Display Server:** Wayland
- **Top Bar:** Custom QML (`DateTime` + `StatusCluster` with Quick Settings drawer)
- **Shelf Dock:** Custom QML (`Dock` with notification badges, Phone Hub & live launcher)
- **Widgets:** 12-sided Cookie Clock, Open-Meteo Weather, Material 3 App Folders
- **Window Decorations:** Native C++ KDecoration3 (`org.doodlebookos.decoration`)
- **App Style:** Native C++ Qt6 style (`doodlebookos6`)
- **Clipboard:** Material 3 Masonry Clipboard override (`Meta+V`)
- **Icon Studio:** PySide6/QML desktop icon personalizer for PWAs and apps
- **Typography:** Google Sans Flex (Variable)
- **Wallpaper:** Custom DoodlebookOS Wallpapers (Light & Dark with live contrast adaptation)

🔗 **GitHub Repository & Installer:** [https://github.com/PanOptikuum/DoodlebookOS](https://github.com/PanOptikuum/DoodlebookOS)

☕ **Support development:** [https://ko-fi.com/panoptikuum](https://ko-fi.com/panoptikuum)

Feedback, issues, and ideas are welcome in GitHub Discussions!
```

---

## 2. Reddit: r/kde

### Tytuł posta:
```text
DoodlebookOS Alpha: A native Material 3 Expressive desktop environment suite for KDE Plasma 6 (C++ style, KDecoration3, custom QML applets)
```

### Treść posta:
```markdown
Hi everyone! 👋

I'm excited to share the initial Alpha release of **DoodlebookOS** — an open-source desktop environment suite built natively for **KDE Plasma 6 on Wayland**.

Instead of a typical theme script or surface-level CSS/SVG rice, DoodlebookOS was engineered from the ground up as a native desktop suite to recreate the cohesive, modern Android PC / Googlebook desktop experience (Material 3 Expressive) on top of KDE Plasma 6:

### Key Highlights:
- **Native C++ Components:** Custom Qt6 Application Style (`doodlebookos6.so`) with smooth hover kinetics, plus a native KDecoration3 window decoration (`org.doodlebookos.decoration.so`).
- **Unified 32dp Top Bar:** Split into top-left DateTime (single-column month view) and top-right StatusCluster (media controls, notifications, and an Android-style Quick Settings drawer for Wi-Fi, Bluetooth, Dark Mode, etc.).
- **Live Wallpaper Luminance Adaptation:** Background daemon that samples wallpaper pixels directly behind the top bar pills in real time to dynamically adjust foreground text and icon contrast.
- **52dp Shelf Dock:** Centered taskbar with notification badges, Phone Hub (KDE Connect integration), and a full-screen Material You launcher.
- **Masonry Clipboard (`Meta+V`):** Modern replacement for KDE Klipper popup featuring card previews and pin management.
- **Icon Studio:** Built-in tool for managing and adapting PWA and web app icons to Material 3 shapes.
- **Automated OOBE Installer & Backups:** Comes with a guided PySide6/QML setup wizard that creates a timestamped backup of your existing KDE configuration before applying changes, allowing seamless restoration via `./uninstall.sh`.

### Requirements:
- KDE Plasma 6.0+
- Wayland session
- Primary verified platform: Fedora 40/41+ (compatible with Arch, EndeavourOS, openSUSE Tumbleweed, Ubuntu 24.10+).

Check out the code, screenshots, and guided installer here:
👉 **GitHub:** https://github.com/PanOptikuum/DoodlebookOS

If you'd like to support the project:
☕ **Ko-fi:** https://ko-fi.com/panoptikuum

I'd love to hear your thoughts, feedback, and bug reports!
```

---

## 3. Wykop (#linux, #pokazpulpit) & Polskie Grupy Linuksowe

### Tytuł / Wstęp:
```text
DoodlebookOS v0.9 Alpha — moje autorskie środowisko Material 3 Expressive na KDE Plasma 6 [Link / Zrzuty / Wideo]
```

### Treść wpisu:
```text
Cześć Mirki spod #linux i #pokazpulpit! 👋

Chciałem Wam zaprezentować projekt, nad którym pracowałem przez ostatnie miesiące — DoodlebookOS (wersja Alpha v0.9).

Nie jest to kolejny zwykły motyw ze zmienioną tapetą i kilkoma plikami konfiguracyjnymi. To kompletny, natywny desktop suite stworzony specjalnie dla KDE Plasma 6 na Waylandzie, odtwarzający interfejs Material 3 Expressive znany z nadchodzących laptopów Google z desktopowym Androidem (Googlebook).

Co udało się przygotować:
- Natywne biblioteki C++: autorski styl aplikacji Qt6 oraz dekoracje okien KDecoration3.
- Szyna górna 32dp: pigułka zegara z kalendarzem jednokolumnowym oraz pigułka statusu z wysuwaną szufladą szybkich ustawień (Wi-Fi, Bluetooth, tryb ciemny itd.).
- Dynamiczny kontrast: demon w tle, który na żywo bada jasność tapety pod pigułkami i automatycznie dostosowuje kontrast napisów i ikon.
- Dolny dock 52dp z powiadomieniami, Phone Hubem (integracja z KDE Connect) i pełnoekranowym launcherem.
- Nowoczesny schowek Meta+V: kafelkowy widok historii schowka w stylu Material You zamiast klasycznego Klippera.
- Narzędzie Icon Studio: autorska aplikacja do personalizacji ikon webowych i PWA.
- Graficzny instalator OOBE w PySide6/QML z automatyczną kopią zapasową obecnego pulpitu i pełnym skryptem odinstalowującym (uninstall.sh).

Całość jest otwarta na licencji GPL-3.0.

🔗 Kod i instalator na GitHubie: https://github.com/PanOptikuum/DoodlebookOS
☕ Jeśli projekt Ci się podoba, możesz postawić kawkę na Ko-fi: https://ko-fi.com/panoptikuum

Dajcie znać w komentarzach co myślicie!
```

---

## 4. Twitter / X

```text
Introducing DoodlebookOS (v0.9 Alpha) 🚀

A complete Material 3 Expressive desktop environment suite crafted natively for KDE Plasma 6 on Wayland!

✨ Native Qt6 & KDecoration3 C++ styles
✨ Dynamic wallpaper luminance contrast
✨ 52dp Shelf Dock & Phone Hub
✨ Meta+V Masonry Clipboard
✨ Guided OOBE Setup Wizard

100% open source (GPLv3).

🔗 GitHub: https://github.com/PanOptikuum/DoodlebookOS
☕ Support: https://ko-fi.com/panoptikuum

#Linux #KDE #Plasma6 #OpenSource #MaterialDesign #Fedora #ArchLinux
```

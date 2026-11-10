#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# SPDX-FileCopyrightText: 2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
"""
DoodlebookOS — Icon Studio (Icon Customizer)
A lightweight Material 3 tool for customizing application & launcher icons
following the FreeDesktop XDG Icon Theme specification.
"""

import os
import re
import sys
import time
import shutil
import base64
import urllib.parse
import subprocess
from pathlib import Path
import io
from PIL import Image

from PySide6.QtCore import QObject, Signal, Slot, Property, QUrl
from PySide6.QtWidgets import QApplication, QFileDialog
from PySide6.QtQml import QQmlApplicationEngine


GOOGLE_WEB_PATTERNS = [
    r"google", r"chrome", r"gmail", r"drive", r"docs", r"sheets", r"slides",
    r"youtube", r"maps", r"calendar", r"photos", r"meet", r"translate",
    r"chromium", r"brave", r"pwa"
]


class IconStudioBackend(QObject):
    appsChanged = Signal()
    statusMessage = Signal(str, bool)  # message, is_success

    def __init__(self):
        super().__init__()
        self._apps = []
        self._icons_base = Path.home() / ".local" / "share" / "icons"
        self._hicolor_dir = self._icons_base / "hicolor"
        self._doodle_theme_dir = self._icons_base / "DoodlebookOS"
        self._backup_dir = Path.home() / ".local" / "share" / "doodlebookos" / "icon-backups"
        self._custom_icons_dir = Path.home() / ".local" / "share" / "doodlebookos" / "custom-icons"
        self._user_apps_dir = Path.home() / ".local" / "share" / "applications"
        self._system_apps_dir = Path("/usr/share/applications")

        # Ensure base directories exist
        self._custom_icons_dir.mkdir(parents=True, exist_ok=True)
        self._user_apps_dir.mkdir(parents=True, exist_ok=True)
        self._backup_dir.mkdir(parents=True, exist_ok=True)
        (self._hicolor_dir / "scalable" / "apps").mkdir(parents=True, exist_ok=True)
        (self._doodle_theme_dir / "scalable" / "apps").mkdir(parents=True, exist_ok=True)

        self._search_dirs = self._get_search_dirs()
        self.refreshApps()

    def _get_search_dirs(self) -> list:
        """Resolve all standard XDG application directories."""
        dirs = [self._user_apps_dir]
        xdg_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
        for d in xdg_dirs:
            if d:
                cand = Path(d) / "applications"
                if cand.exists() and cand not in dirs:
                    dirs.append(cand)
        if self._system_apps_dir.exists() and self._system_apps_dir not in dirs:
            dirs.append(self._system_apps_dir)
        return dirs

    @Property(list, notify=appsChanged)
    def apps(self):
        return self._apps

    def _normalize_path(self, file_path: str) -> str:
        """Strip file:// and sanitize path, handling URL encoding like %20."""
        file_path = urllib.parse.unquote(file_path)
        if file_path.startswith("file://"):
            file_path = file_path[7:]
        return os.path.abspath(os.path.expanduser(file_path))

    def _format_icon_source(self, icon: str, app_id: str = "") -> str:
        """Format icon for QML Kirigami.Icon, preferring custom files directly if present."""
        if not icon:
            return "application-x-executable"

        # If custom icon file exists on disk, provide local URL directly
        if app_id:
            safe_id = Path(app_id).stem
            for cand_ext in (".svg", ".png"):
                custom_f = self._custom_icons_dir / f"{safe_id}{cand_ext}"
                if custom_f.exists():
                    return QUrl.fromLocalFile(str(custom_f)).toString()
                theme_f = self._hicolor_dir / "scalable" / "apps" / f"{safe_id}{cand_ext}"
                if theme_f.exists():
                    return QUrl.fromLocalFile(str(theme_f)).toString()

        if icon.startswith("/"):
            return QUrl.fromLocalFile(icon).toString()
        return icon

    def _get_launcher_custom_icon(self) -> str:
        """Read launcher custom icon path if configured or existing in custom dir."""
        for ext in (".svg", ".png", ".webp"):
            candidate = self._custom_icons_dir / f"launcher{ext}"
            if candidate.exists():
                return str(candidate)
        return ""

    @Slot()
    def refreshApps(self):
        """Scan applications and construct the app list."""
        self._search_dirs = self._get_search_dirs()
        apps_map = {}

        # 1. Launcher special item
        launcher_custom = self._get_launcher_custom_icon()
        apps_map["__launcher__"] = {
            "id": "__launcher__",
            "name": 'Launcher Button ("D")',
            "comment": "Bottom shelf menu button icon",
            "icon": self._format_icon_source(launcher_custom) if launcher_custom else "preferences-desktop-theme",
            "defaultIcon": "preferences-desktop-theme",
            "category": "Launcher",
            "isModified": bool(launcher_custom),
            "isLauncher": True,
            "desktopPath": ""
        }

        # 2. Collect desktop files across all search directories
        # Earlier dirs take precedence over later ones
        desktop_files = {}
        for s_dir in reversed(self._search_dirs):
            if not s_dir.exists():
                continue
            for p in s_dir.glob("*.desktop"):
                desktop_files[p.name] = p

        # 3. User overrides set
        user_overrides = set()
        if self._user_apps_dir.exists():
            for p in self._user_apps_dir.glob("*.desktop"):
                user_overrides.add(p.name)

        # 4. Parse desktop files
        for filename, filepath in desktop_files.items():
            parsed = self._parse_desktop_file(filepath)
            if not parsed or parsed.get("NoDisplay", False):
                continue

            app_id = filename
            name = parsed.get("Name", app_id)
            icon = parsed.get("Icon", "application-x-executable")
            comment = parsed.get("Comment", "")

            # Check if modified by user
            safe_id = Path(filename).stem
            has_custom_icon = any(self._custom_icons_dir.glob(f"{safe_id}.*"))
            has_backup_key = "OriginalIcon" in parsed
            has_backup_folder = (self._backup_dir / filename).exists()
            has_theme_override = (self._hicolor_dir / "scalable" / "apps" / f"{safe_id}.svg").exists()
            is_modified = has_custom_icon or has_backup_key or has_backup_folder or has_theme_override

            # Categorize
            category = "System"
            lower_name = (name + " " + app_id + " " + comment).lower()
            if any(re.search(pat, lower_name) for pat in GOOGLE_WEB_PATTERNS):
                category = "Google / Web"

            apps_map[app_id] = {
                "id": app_id,
                "name": name,
                "comment": comment,
                "icon": self._format_icon_source(icon, app_id),
                "defaultIcon": parsed.get("DefaultIcon", icon),
                "category": category,
                "isModified": is_modified,
                "isLauncher": False,
                "desktopPath": str(filepath)
            }

        # Convert to list: Launcher first, then alphabetical by name
        app_list = []
        if "__launcher__" in apps_map:
            app_list.append(apps_map.pop("__launcher__"))

        sorted_apps = sorted(apps_map.values(), key=lambda x: x["name"].lower())
        app_list.extend(sorted_apps)

        self._apps = app_list
        self.appsChanged.emit()

    def _parse_desktop_file(self, path: Path) -> dict:
        """Extract Name, Icon, NoDisplay, Comment from [Desktop Entry] section."""
        data = {}
        in_entry = False
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    if line == "[Desktop Entry]":
                        in_entry = True
                        continue
                    elif line.startswith("[") and in_entry:
                        break  # End of main section

                    if in_entry and "=" in line:
                        k, v = line.split("=", 1)
                        k = k.strip()
                        v = v.strip()
                        if k == "Name" and "Name" not in data:
                            data["Name"] = v
                        elif k == "Icon" and "Icon" not in data:
                            data["Icon"] = v
                        elif k == "Comment" and "Comment" not in data:
                            data["Comment"] = v
                        elif k == "X-Doodlebook-Original-Icon":
                            data["OriginalIcon"] = v
                        elif k == "NoDisplay":
                            data["NoDisplay"] = v.lower() == "true"
                        elif k == "Type" and v != "Application":
                            return None
        except Exception:
            return None

        # Check default system icon if user override exists
        if path.parent == self._user_apps_dir:
            for s_dir in self._search_dirs:
                if s_dir == self._user_apps_dir:
                    continue
                sys_file = s_dir / path.name
                if sys_file.exists():
                    sys_parsed = self._parse_desktop_file(sys_file)
                    if sys_parsed and "Icon" in sys_parsed:
                        data["DefaultIcon"] = sys_parsed["Icon"]
                        break

        return data

    @Slot(str)
    def pickIconForApp(self, app_id: str):
        """Open the native system file dialog to pick an icon."""
        file_path, _ = QFileDialog.getOpenFileName(
            None,
            "Select Icon (SVG, PNG, WebP)",
            str(Path.home()),
            "Image Files (*.svg *.png *.webp *.jpg *.jpeg);;All Files (*)"
        )
        if file_path:
            self.setAppIcon(app_id, file_path)

    @Slot(str, str)
    def setAppIcon(self, app_id: str, file_path: str):
        """Set a custom icon for an app or launcher."""
        file_path = self._normalize_path(file_path)
        if not os.path.isfile(file_path):
            self.statusMessage.emit("Selected file does not exist.", False)
            return

        ext = Path(file_path).suffix.lower()
        if ext not in (".svg", ".png", ".webp", ".jpg", ".jpeg"):
            self.statusMessage.emit("Supported formats: SVG, PNG, WebP.", False)
            return

        try:
            if app_id == "__launcher__":
                self._apply_launcher_icon(file_path, ext)
            else:
                self._apply_app_icon(app_id, file_path, ext)

            self.refreshApps()
            self.statusMessage.emit("Icon updated successfully!", True)
        except Exception as e:
            self.statusMessage.emit(f"Error changing icon: {e}", False)

    def _apply_launcher_icon(self, source_path: str, ext: str):
        """Copy icon and set launcherIcon in Plasmoid via Plasma scripting DBus."""
        # 1. Clean previous custom launcher icons
        for f in self._custom_icons_dir.glob("launcher.*"):
            try:
                f.unlink()
            except OSError:
                pass

        dest_icon = self._custom_icons_dir / f"launcher{ext}"
        shutil.copyfile(source_path, dest_icon)

        # 2. Update Dock Plasmoid config dynamically
        script = f'''
for (let p of panels()) {{
    for (let w of p.widgets()) {{
        if (w.type === "org.doodlebookos.dock") {{
            w.currentConfigGroup = ["General"];
            w.writeConfig("launcherIcon", "{str(dest_icon)}");
        }}
    }}
}}
'''
        self._run_plasma_script(script)

    def _exists_in_system(self, app_id: str) -> Path | None:
        """Check if an app exists in system search directories."""
        for s_dir in self._search_dirs:
            if s_dir == self._user_apps_dir:
                continue
            cand = s_dir / app_id
            if cand.exists():
                return cand
        return None

    def _resolve_target_desktops(self, app_id: str) -> list[Path]:
        """Find the user .desktop file, copying from system if needed, and related JetBrains siblings."""
        target = self._user_apps_dir / app_id
        if not target.exists():
            sys_cand = self._exists_in_system(app_id)
            if sys_cand and sys_cand.exists():
                shutil.copyfile(sys_cand, target)

        if not target.exists():
            return []

        targets = [target]
        # If JetBrains app, also find sibling desktop files in user_apps_dir
        clean_stem = Path(app_id).stem
        if clean_stem.startswith("jetbrains-"):
            parts = clean_stem.split("-")
            if len(parts) >= 2:
                prefix = f"jetbrains-{parts[1]}"  # e.g. "jetbrains-studio"
                for sibling in self._user_apps_dir.glob(f"{prefix}*.desktop"):
                    if sibling not in targets:
                        targets.append(sibling)

        return targets

    def _prepare_icon_assets(self, source_path: str, ext: str) -> tuple[str, bytes | None]:
        """Prepare SVG content and optional raw PNG bytes."""
        if ext == ".svg":
            with open(source_path, "r", encoding="utf-8", errors="replace") as f:
                svg_content = f.read()
            return svg_content, None
        else:
            with Image.open(source_path) as im:
                w, h = im.size
                buf = io.BytesIO()
                im.save(buf, format="PNG")
                png_bytes = buf.getvalue()
                b64 = base64.b64encode(png_bytes).decode("ascii")
                svg_content = f'''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 {w} {h}" width="{w}" height="{h}">
  <image width="{w}" height="{h}" xlink:href="data:image/png;base64,{b64}"/>
</svg>'''
                return svg_content, png_bytes

    def _apply_app_icon(self, app_id: str, source_path: str, ext: str):
        """Install custom icon to XDG icon theme hierarchies and update .desktop entries."""
        target_desktops = self._resolve_target_desktops(app_id)
        if not target_desktops:
            raise FileNotFoundError(f"Desktop file not found for {app_id}")

        svg_content, raw_png_bytes = self._prepare_icon_assets(source_path, ext)

        for desktop_path in target_desktops:
            self._apply_single_desktop_icon(desktop_path, svg_content, raw_png_bytes)

        # Invalidate caches and trigger dock refresh
        self._invalidate_icon_caches()
        self._trigger_dock_apps_refresh()

    def _apply_single_desktop_icon(self, desktop_path: Path, svg_content: str, raw_png_bytes: bytes | None):
        """Apply icon to a single .desktop file, backing up conflicting theme icons."""
        # 1. Parse existing desktop file
        content_lines = []
        original_icon = None
        has_backup_key = False

        with open(desktop_path, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                stripped = line.strip()
                if stripped.startswith("Icon="):
                    val = stripped[5:].strip()
                    if not original_icon:
                        original_icon = val
                elif stripped.startswith("X-Doodlebook-Original-Icon="):
                    has_backup_key = True
                    original_icon = stripped[len("X-Doodlebook-Original-Icon="):].strip()

        # Determine clean icon token
        safe_stem = desktop_path.stem
        if original_icon and not original_icon.startswith("/") and not original_icon.endswith((".png", ".svg")):
            icon_token = original_icon
        else:
            icon_token = safe_stem

        # 2. Backup conflicting theme icons in hicolor, DoodlebookOS, DoodlebookOS-Themed
        app_backup_dir = self._backup_dir / desktop_path.name
        app_backup_dir.mkdir(parents=True, exist_ok=True)

        for theme_name in ("hicolor", "DoodlebookOS", "DoodlebookOS-Themed"):
            theme_dir = self._icons_base / theme_name
            if not theme_dir.exists():
                continue
            for match in theme_dir.glob(f"**/{icon_token}.*"):
                # Do not back up our own custom scalable svg if re-modifying
                if match.suffix == ".svg" and "scalable/apps" in str(match):
                    continue
                try:
                    rel = match.relative_to(theme_dir)
                    dest_backup = app_backup_dir / theme_name / rel
                    dest_backup.parent.mkdir(parents=True, exist_ok=True)
                    if not dest_backup.exists():
                        shutil.move(match, dest_backup)
                    else:
                        match.unlink()
                except Exception:
                    pass

        # 3. Write SVG to standard XDG theme locations
        hicolor_svg = self._hicolor_dir / "scalable" / "apps" / f"{icon_token}.svg"
        doodle_svg = self._doodle_theme_dir / "scalable" / "apps" / f"{icon_token}.svg"
        custom_ref_svg = self._custom_icons_dir / f"{safe_stem}.svg"

        hicolor_svg.parent.mkdir(parents=True, exist_ok=True)
        doodle_svg.parent.mkdir(parents=True, exist_ok=True)

        for p in (hicolor_svg, doodle_svg, custom_ref_svg):
            with open(p, "w", encoding="utf-8") as f:
                f.write(svg_content)

        # 4. If PNG bytes available, write to 512x512
        if raw_png_bytes:
            for theme_dir in (self._hicolor_dir, self._doodle_theme_dir):
                png_path = theme_dir / "512x512" / "apps" / f"{icon_token}.png"
                png_path.parent.mkdir(parents=True, exist_ok=True)
                with open(png_path, "wb") as f:
                    f.write(raw_png_bytes)

        # 5. Update .desktop file with clean Icon token and backup key
        new_lines = []
        with open(desktop_path, "r", encoding="utf-8", errors="replace") as f:
            in_desktop_entry = False
            for line in f:
                stripped = line.strip()
                if stripped == "[Desktop Entry]":
                    in_desktop_entry = True
                    new_lines.append(line)
                    if not has_backup_key and original_icon:
                        new_lines.append(f"X-Doodlebook-Original-Icon={original_icon}\n")
                    continue
                elif stripped.startswith("["):
                    in_desktop_entry = False

                if in_desktop_entry and stripped.startswith("Icon="):
                    new_lines.append(f"Icon={icon_token}\n")
                elif in_desktop_entry and stripped.startswith("X-Doodlebook-Original-Icon="):
                    new_lines.append(f"X-Doodlebook-Original-Icon={original_icon}\n")
                else:
                    new_lines.append(line)

        with open(desktop_path, "w", encoding="utf-8") as f:
            f.writelines(new_lines)

    @Slot(str)
    def resetAppIcon(self, app_id: str):
        """Restore default icon safely, recovering backed-up theme icons."""
        try:
            if app_id == "__launcher__":
                for f in self._custom_icons_dir.glob("launcher.*"):
                    try:
                        f.unlink()
                    except OSError:
                        pass
                script = '''
for (let p of panels()) {
    for (let w of p.widgets()) {
        if (w.type === "org.doodlebookos.dock") {
            w.currentConfigGroup = ["General"];
            w.writeConfig("launcherIcon", "");
        }
    }
}
'''
                self._run_plasma_script(script)
            else:
                target_desktops = self._resolve_target_desktops(app_id)
                for desktop_path in target_desktops:
                    self._reset_single_desktop_icon(desktop_path)

                self._invalidate_icon_caches()
                self._trigger_dock_apps_refresh()

            self.refreshApps()
            self.statusMessage.emit("Default icon restored.", True)
        except Exception as e:
            self.statusMessage.emit(f"Error resetting icon: {e}", False)

    def _reset_single_desktop_icon(self, desktop_path: Path):
        """Reset a single .desktop file and its backed-up icons."""
        safe_stem = desktop_path.stem

        # 1. Read desktop file to find original icon
        original_icon = None
        has_backup_key = False
        content_lines = []

        if desktop_path.exists():
            with open(desktop_path, "r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    stripped = line.strip()
                    if stripped.startswith("X-Doodlebook-Original-Icon="):
                        has_backup_key = True
                        original_icon = stripped[len("X-Doodlebook-Original-Icon="):].strip()
                    elif stripped.startswith("Icon="):
                        if not original_icon:
                            original_icon = stripped[5:].strip()

        icon_token = original_icon if (original_icon and not original_icon.startswith("/") and not original_icon.endswith((".png", ".svg"))) else safe_stem

        # 2. Remove our custom files from theme locations
        for p in [
            self._hicolor_dir / "scalable" / "apps" / f"{icon_token}.svg",
            self._doodle_theme_dir / "scalable" / "apps" / f"{icon_token}.svg",
            self._hicolor_dir / "512x512" / "apps" / f"{icon_token}.png",
            self._doodle_theme_dir / "512x512" / "apps" / f"{icon_token}.png",
            self._custom_icons_dir / f"{safe_stem}.svg",
            self._custom_icons_dir / f"{safe_stem}.png",
            self._custom_icons_dir / f"{icon_token}.svg",
            self._custom_icons_dir / f"{icon_token}.png",
        ]:
            if p.exists():
                try:
                    p.unlink()
                except OSError:
                    pass

        # 3. Restore backed up theme icons
        app_backup_dir = self._backup_dir / desktop_path.name
        if app_backup_dir.exists():
            for root, _, files in os.walk(app_backup_dir):
                for fname in files:
                    src_file = Path(root) / fname
                    rel = src_file.relative_to(app_backup_dir)
                    dest_file = self._icons_base / rel
                    dest_file.parent.mkdir(parents=True, exist_ok=True)
                    try:
                        shutil.move(src_file, dest_file)
                    except Exception:
                        pass
            try:
                shutil.rmtree(app_backup_dir)
            except OSError:
                pass

        # 4. Restore .desktop file
        system_desktop = self._exists_in_system(desktop_path.name)
        if system_desktop and desktop_path.exists():
            # If it was a system app clone with no other customizations, remove user override
            try:
                desktop_path.unlink()
            except OSError:
                pass
        elif desktop_path.exists():
            # User-only app (e.g. Chrome PWA, Toolbox IDE): restore original icon
            final_lines = []
            with open(desktop_path, "r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    stripped = line.strip()
                    if stripped.startswith("X-Doodlebook-Original-Icon="):
                        continue
                    if stripped.startswith("Icon=") and original_icon:
                        final_lines.append(f"Icon={original_icon}\n")
                    else:
                        final_lines.append(line)
            with open(desktop_path, "w", encoding="utf-8") as f:
                f.writelines(final_lines)

    def _invalidate_icon_caches(self):
        """Update directory timestamps and rebuild Sycoca and GTK icon caches."""
        try:
            self._hicolor_dir.mkdir(parents=True, exist_ok=True)
            self._doodle_theme_dir.mkdir(parents=True, exist_ok=True)
            os.utime(self._hicolor_dir, None)
            os.utime(self._doodle_theme_dir, None)
        except Exception:
            pass

        subprocess.run(["gtk-update-icon-cache", "-f", "-t", str(self._hicolor_dir)],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["gtk-update-icon-cache", "-f", "-t", str(self._doodle_theme_dir)],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["kbuildsycoca6", "--noincremental"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    @Slot()
    def reloadPlasma(self):
        """Restart plasma-plasmashell.service to force a full desktop refresh."""
        try:
            subprocess.run(["systemctl", "--user", "restart", "plasma-plasmashell.service"], check=True)
            self.statusMessage.emit("Plasma reloaded successfully!", True)
        except Exception as e:
            self.statusMessage.emit(f"Failed to reload Plasma: {e}", False)

    def _trigger_dock_apps_refresh(self):
        """Notify the Dock Plasmoid to refresh its Kicker rootModel immediately."""
        script = f'''
for (let p of panels()) {{
    for (let w of p.widgets()) {{
        if (w.type === "org.doodlebookos.dock") {{
            w.currentConfigGroup = ["General"];
            w.writeConfig("appsRefreshTrigger", {int(time.time())});
        }}
    }}
}}
'''
        self._run_plasma_script(script)

    def _run_plasma_script(self, script: str):
        try:
            subprocess.run(
                ["qdbus-qt6", "org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell.evaluateScript", script],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=2.0
            )
        except Exception:
            pass


def main():
    app = QApplication(sys.argv)
    app.setApplicationName("Icon Studio")
    app.setOrganizationName("DoodlebookOS")

    backend = IconStudioBackend()

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("backend", backend)

    qml_file = Path(__file__).parent / "ui" / "Main.qml"
    engine.load(QUrl.fromLocalFile(str(qml_file)))

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()

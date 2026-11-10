#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
import configparser
import glob
import json
import os
import re

def main():
    apps = []
    seen = set()

    paths = [
        os.path.expanduser("~/.local/share/applications/*.desktop"),
        os.path.expanduser("~/.local/share/flatpak/exports/share/applications/*.desktop"),
        "/var/lib/flatpak/exports/share/applications/*.desktop",
        "/usr/local/share/applications/*.desktop",
        "/usr/share/applications/*.desktop",
    ]

    for pattern in paths:
        for p in glob.glob(pattern):
            cp = configparser.ConfigParser(interpolation=None)
            try:
                cp.read(p, encoding="utf-8")
                if "Desktop Entry" not in cp:
                    continue
                de = cp["Desktop Entry"]
                if de.get("NoDisplay", "false").lower() == "true":
                    continue
                if de.get("Hidden", "false").lower() == "true":
                    continue
                if de.get("Type", "") != "Application":
                    continue
                name = (de.get("Name") or "").strip()
                icon = (de.get("Icon") or "application-x-executable").strip()
                raw_exec = (de.get("Exec") or "").strip()
                if not name or not raw_exec:
                    continue
                clean_exec = re.sub(r"\s+%[fFuUickdDnNickvm]", "", raw_exec).strip()
                key = name.lower()
                if key in seen:
                    continue
                seen.add(key)
                apps.append({
                    "name": name,
                    "icon": icon,
                    "url": "",
                    "exec": clean_exec,
                })
            except Exception:
                pass

    apps.sort(key=lambda x: x["name"].lower())
    print(json.dumps(apps, ensure_ascii=False))

if __name__ == "__main__":
    main()

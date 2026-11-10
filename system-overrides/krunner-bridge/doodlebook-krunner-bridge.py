#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Maciej Kujawiński <maciek.kujawinski@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
import sys
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

INTERFACE_KRUNNER = "org.kde.krunner.App"
PATH_KRUNNER = "/App"
SERVICE_KRUNNER = "org.kde.krunner"

class KRunnerBridge(dbus.service.Object):
    def __init__(self, bus):
        bus_name = dbus.service.BusName(SERVICE_KRUNNER, bus=bus, do_not_queue=True)
        super().__init__(bus_name, PATH_KRUNNER)
        self.bus = bus
        self.trigger_count = 0
        self.query_text = ""

    @dbus.service.method(dbus.PROPERTIES_IFACE, in_signature='ss', out_signature='v')
    def Get(self, interface_name, property_name):
        return self.GetAll(interface_name).get(property_name, "")

    @dbus.service.method(dbus.PROPERTIES_IFACE, in_signature='s', out_signature='a{sv}')
    def GetAll(self, interface_name):
        return {
            'triggerCount': dbus.Int32(self.trigger_count),
            'queryText': dbus.String(self.query_text)
        }

    @dbus.service.signal(dbus.PROPERTIES_IFACE, signature='sa{sv}as')
    def PropertiesChanged(self, interface_name, changed_properties, invalidated_properties):
        pass

    def _activate_launcher(self, query=""):
        self.trigger_count += 1
        self.query_text = str(query) if query is not None else ""
        # Emit standard DBus property changed for QML DBus.Properties listener
        try:
            self.PropertiesChanged(
                INTERFACE_KRUNNER,
                {
                    'triggerCount': dbus.Int32(self.trigger_count),
                    'queryText': dbus.String(self.query_text)
                },
                []
            )
        except Exception as e:
            sys.stderr.write(f"PropertiesChanged failed: {e}\n")

    @dbus.service.method(INTERFACE_KRUNNER, in_signature='', out_signature='')
    def display(self):
        self._activate_launcher("")

    @dbus.service.method(INTERFACE_KRUNNER, in_signature='', out_signature='')
    def toggleDisplay(self):
        self._activate_launcher("")

    @dbus.service.method(INTERFACE_KRUNNER, in_signature='s', out_signature='')
    def query(self, term):
        self._activate_launcher(str(term))

    @dbus.service.method(INTERFACE_KRUNNER, in_signature='s', out_signature='')
    def displaySingleRunner(self, runnerName):
        self._activate_launcher("")

    @dbus.service.method(INTERFACE_KRUNNER, in_signature='ss', out_signature='')
    def querySingleRunner(self, runnerName, term):
        self._activate_launcher(str(term))

    @dbus.service.method(INTERFACE_KRUNNER, in_signature='', out_signature='')
    def displayWithClipboardContents(self):
        self._activate_launcher("")

def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    try:
        session_bus = dbus.SessionBus()
    except Exception as e:
        sys.stderr.write(f"Failed to connect to session bus: {e}\n")
        sys.exit(1)

    try:
        bridge = KRunnerBridge(session_bus)
    except Exception as e:
        sys.stderr.write(f"Failed to claim {SERVICE_KRUNNER}: {e}\n")
        sys.exit(1)

    loop = GLib.MainLoop()
    try:
        loop.run()
    except (KeyboardInterrupt, SystemExit):
        loop.quit()

if __name__ == "__main__":
    main()

/*
 * SPDX-FileCopyrightText: 2026 DoodlebookOS
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include "settingsprovider.h"

namespace DoodlebookOS
{
SettingsProvider *SettingsProvider::s_self = nullptr;

SettingsProvider::SettingsProvider()
    : m_config(KSharedConfig::openConfig(QStringLiteral("doodlebookosrc")))
{
    reconfigure();
}

SettingsProvider::~SettingsProvider()
{
    s_self = nullptr;
}

SettingsProvider *SettingsProvider::self()
{
    if (!s_self) {
        s_self = new SettingsProvider();
    }
    return s_self;
}

void SettingsProvider::reconfigure()
{
    if (!m_defaultSettings) {
        m_defaultSettings = InternalSettingsPtr(new InternalSettings());
        m_defaultSettings->setCurrentGroup(QStringLiteral("Windeco"));
    }
    m_defaultSettings->load();
}

InternalSettingsPtr SettingsProvider::internalSettings(Decoration *) const
{
    return m_defaultSettings;
}

} // namespace DoodlebookOS

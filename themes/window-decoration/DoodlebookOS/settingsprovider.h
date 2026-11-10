/*
 * SPDX-FileCopyrightText: 2026 DoodlebookOS
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#pragma once

#include "types.h"
#include "settings.h"

#include <KSharedConfig>
#include <QObject>

namespace DoodlebookOS
{
class Decoration;

class SettingsProvider : public QObject
{
    Q_OBJECT

public:
    ~SettingsProvider();

    static SettingsProvider *self();

    InternalSettingsPtr internalSettings(Decoration *decoration = nullptr) const;

public Q_SLOTS:
    void reconfigure();

private:
    SettingsProvider();

    InternalSettingsPtr m_defaultSettings;
    KSharedConfigPtr m_config;
    static SettingsProvider *s_self;
};

} // namespace DoodlebookOS

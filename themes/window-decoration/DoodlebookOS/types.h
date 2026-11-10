/*
 * SPDX-FileCopyrightText: 2026 DoodlebookOS
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#pragma once

#include "settings.h"

#include <QList>
#include <QSharedPointer>

namespace DoodlebookOS
{
//* convenience typedefs
using InternalSettingsPtr = QSharedPointer<InternalSettings>;
using InternalSettingsList = QList<InternalSettingsPtr>;

namespace Metrics
{
static constexpr qreal Frame_FrameRadius = 2.5;
static constexpr int Shadow_Overlap = 3;
}

enum ExceptionMask {
    None = 0,
    BorderSize = 1 << 4,
};
}

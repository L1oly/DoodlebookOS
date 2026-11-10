/*
 * SPDX-FileCopyrightText: 2014 Hugo Pereira Da Costa <hugo.pereira@free.fr>
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "styleplugin.h"
#include "style.h"

#include <QApplication>

namespace DoodlebookOS
{
//_________________________________________________
QStyle *StylePlugin::create(const QString &key)
{
    if (key.compare(QLatin1String("doodlebookos"), Qt::CaseInsensitive) == 0 || key.compare(QLatin1String("DoodlebookOS"), Qt::CaseInsensitive) == 0) {
        return new Style;
    }
    return nullptr;
}

//_________________________________________________
QStringList StylePlugin::keys() const
{
    return QStringList({QStringLiteral("DoodlebookOS")});
}

}

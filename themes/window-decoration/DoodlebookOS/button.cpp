/*
 * SPDX-FileCopyrightText: 2026 DoodlebookOS
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include "button.h"
#include "decoration.h"

#include <KColorUtils>
#include <KDecoration3/DecoratedWindow>
#include <KDecoration3/ScaleHelpers>
#include <KIconLoader>

#include <QPainter>
#include <QPainterPath>
#include <QVariantAnimation>
#include <QSvgRenderer>
#include <QHash>

namespace DoodlebookOS
{
using KDecoration3::ColorGroup;
using KDecoration3::ColorRole;
using KDecoration3::DecorationButtonType;

static constexpr const char s_svgClose[] =
    R"(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" height="24px" width="24px" fill="#e3e3e3"><path d="M12,13.4L7.1,18.3q-0.28,0.27-0.7,0.27T5.7,18.3q-0.27-0.28-0.27-0.7T5.7,16.9L10.6,12L5.7,7.1Q5.43,6.82 5.43,6.4T5.7,5.7T6.4,5.43T7.1,5.7L12,10.6l4.9-4.9q0.27-0.27 0.7-0.27T18.3,5.7t0.27,0.7T18.3,7.1L13.4,12l4.9,4.9q0.27,0.28 0.27,0.7q0,0.42-0.27,0.7t-0.7,0.27T16.9,18.3L12,13.4Z"/></svg>)";

static constexpr const char s_svgMaximize[] =
    R"(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" height="24px" width="24px" fill="#e3e3e3"><path d="M5,21q-0.83,0-1.41-0.59T3,19V5Q3,4.17 3.59,3.59T5,3H19q0.83,0 1.41,0.59T21,5V19q0,0.82-0.59,1.41T19,21H5Zm0-2H19V5H5V19Zm0,0V5V19Z"/></svg>)";

static void renderSvgIcon(QPainter *painter, const char *svgData, const QRectF &targetRect, const QColor &color)
{
    static QHash<const void *, QSvgRenderer *> renderers;
    if (!renderers.contains(svgData)) {
        auto renderer = new QSvgRenderer();
        renderer->load(QByteArray::fromRawData(svgData, qstrlen(svgData)));
        renderers[svgData] = renderer;
    }
    QSvgRenderer *renderer = renderers[svgData];
    if (!renderer || !renderer->isValid()) {
        return;
    }

    const int renderSize = 64;
    static QHash<quint64, QImage> cache;
    const quint64 key = (static_cast<quint64>(reinterpret_cast<quintptr>(svgData)) << 32) | static_cast<quint64>(color.rgba());

    auto it = cache.constFind(key);
    if (it == cache.constEnd()) {
        QImage img(renderSize, renderSize, QImage::Format_ARGB32_Premultiplied);
        img.fill(Qt::transparent);

        QPainter imgPainter(&img);
        imgPainter.setRenderHints(QPainter::Antialiasing | QPainter::SmoothPixmapTransform);
        renderer->render(&imgPainter, QRectF(0, 0, renderSize, renderSize));
        imgPainter.end();

        QPainter tintPainter(&img);
        tintPainter.setCompositionMode(QPainter::CompositionMode_SourceIn);
        tintPainter.fillRect(img.rect(), color);
        tintPainter.end();

        it = cache.insert(key, img);
    }

    painter->drawImage(targetRect, it.value());
}

//__________________________________________________________________
Button::Button(DecorationButtonType type, Decoration *decoration, QObject *parent)
    : DecorationButton(type, decoration, parent)
    , m_animation(new QVariantAnimation(this))
{
    m_animation->setStartValue(0.0);
    m_animation->setEndValue(1.0);
    m_animation->setDuration(150);
    m_animation->setEasingCurve(QEasingCurve::OutCubic);
    connect(m_animation, &QVariantAnimation::valueChanged, this, [this](const QVariant &value) {
        setOpacity(value.toReal());
    });

    connect(decoration->window(), SIGNAL(iconChanged(QIcon)), this, SLOT(update()));
    connect(decoration->settings().get(), &KDecoration3::DecorationSettings::reconfigured, this, &Button::reconfigure);
    connect(this, &KDecoration3::DecorationButton::hoveredChanged, this, &Button::updateAnimationState);

    reconfigure();
}

//__________________________________________________________________
Button::Button(QObject *parent, const QVariantList &args)
    : Button(args.at(0).value<DecorationButtonType>(), args.at(1).value<Decoration *>(), parent)
{
    setGeometry(QRectF(QPointF(0, 0), preferredSize()));
}

//__________________________________________________________________
Button *Button::create(DecorationButtonType type, KDecoration3::Decoration *decoration, QObject *parent)
{
    if (auto d = qobject_cast<Decoration *>(decoration)) {
        if (type != DecorationButtonType::Menu &&
            type != DecorationButtonType::Minimize &&
            type != DecorationButtonType::Maximize &&
            type != DecorationButtonType::Close) {
            return nullptr;
        }

        Button *b = new Button(type, d, parent);
        const auto c = d->window();
        switch (type) {
        case DecorationButtonType::Close:
            b->setVisible(c->isCloseable());
            QObject::connect(c, &KDecoration3::DecoratedWindow::closeableChanged, b, &DoodlebookOS::Button::setVisible);
            break;

        case DecorationButtonType::Maximize:
            b->setVisible(c->isMaximizeable());
            QObject::connect(c, &KDecoration3::DecoratedWindow::maximizeableChanged, b, &DoodlebookOS::Button::setVisible);
            break;

        case DecorationButtonType::Minimize:
            b->setVisible(c->isMinimizeable());
            QObject::connect(c, &KDecoration3::DecoratedWindow::minimizeableChanged, b, &DoodlebookOS::Button::setVisible);
            break;

        case DecorationButtonType::Menu:
            QObject::connect(c, &KDecoration3::DecoratedWindow::iconChanged, b, [b]() {
                b->update();
            });
            break;

        default:
            break;
        }

        return b;
    }

    return nullptr;
}

//__________________________________________________________________
void Button::paint(QPainter *painter, const QRectF &repaintRegion)
{
    Q_UNUSED(repaintRegion)

    if (!decoration()) {
        return;
    }

    switch (type()) {
    case KDecoration3::DecorationButtonType::Menu: {
        painter->setRenderHints(QPainter::Antialiasing | QPainter::SmoothPixmapTransform);
        const auto c = decoration()->window();
        if (!c) {
            break;
        }

        const auto deco = qobject_cast<Decoration *>(decoration());
        const qreal scale = deco ? deco->effectiveScale() : 1.25;

        const qreal targetSide = KDecoration3::snapToPixelGrid(25.0 / scale, scale);
        const QRectF box(geometry().topLeft(), QSizeF(targetSide, targetSide));

        QIcon icon = c->icon();
        if (icon.isNull()) {
            icon = QIcon::fromTheme(QStringLiteral("application-x-executable"));
        }
        if (!icon.isNull()) {
            const int physicalSide = qRound(targetSide * scale);
            const QPixmap px = icon.pixmap(QSize(physicalSide, physicalSide));
            if (!px.isNull()) {
                painter->drawPixmap(box.toRect(), px);
            }
        }
        break;
    }

    case KDecoration3::DecorationButtonType::Close:
    case KDecoration3::DecorationButtonType::Maximize:
    case KDecoration3::DecorationButtonType::Minimize: {
        painter->save();

        const QColor backgroundColor(this->backgroundColor());
        if (backgroundColor.isValid()) {
            painter->setRenderHints(QPainter::Antialiasing);
            painter->setPen(Qt::NoPen);
            painter->setBrush(backgroundColor);

            const auto deco = qobject_cast<Decoration *>(decoration());
            const qreal scale = deco ? deco->effectiveScale() : 1.25;
            const qreal diameter = KDecoration3::snapToPixelGrid(34.0 / scale, scale);
            const QPointF center = geometry().center();
            const QRectF circleRect(center.x() - diameter / 2.0, center.y() - diameter / 2.0, diameter, diameter);

            painter->drawEllipse(circleRect);
        }

        drawIcon(painter);
        painter->restore();
        break;
    }

    default:
        break;
    }
}

//__________________________________________________________________
void Button::drawIcon(QPainter *painter) const
{
    const QRectF rect = geometry();
    const QPointF center = rect.center();
    const auto deco = qobject_cast<Decoration *>(decoration());
    const qreal scale = deco ? deco->effectiveScale() : 1.25;

    const qreal iconSide = KDecoration3::snapToPixelGrid((14.0 * 24.0 / 18.0) / scale, scale);
    const QRectF iconRect(center.x() - iconSide / 2.0, center.y() - iconSide / 2.0, iconSide, iconSide);

    const QColor foregroundColor = this->foregroundColor();
    if (!foregroundColor.isValid()) {
        return;
    }

    switch (type()) {
    case DecorationButtonType::Close:
        renderSvgIcon(painter, s_svgClose, iconRect, foregroundColor);
        return;

    case DecorationButtonType::Maximize:
        renderSvgIcon(painter, s_svgMaximize, iconRect, foregroundColor);
        return;

    case DecorationButtonType::Minimize: {
        const qreal minW = KDecoration3::snapToPixelGrid(14.0 / scale, scale);
        const qreal minH = KDecoration3::snapToPixelGrid(2.0 / scale, scale);
        const qreal boxBottom = center.y() + KDecoration3::snapToPixelGrid(7.0 / scale, scale);
        const QRectF minRect(center.x() - minW / 2.0, boxBottom - minH, minW, minH);
        painter->setPen(Qt::NoPen);
        painter->setBrush(foregroundColor);
        painter->drawRoundedRect(minRect, minH / 2.0, minH / 2.0);
        return;
    }

    default:
        break;
    }
}

//__________________________________________________________________
QColor Button::foregroundColor() const
{
    auto d = qobject_cast<Decoration *>(decoration());
    if (!d) {
        return QColor();
    }
    return d->fontColor();
}

//__________________________________________________________________
QColor Button::backgroundColor() const
{
    auto d = qobject_cast<Decoration *>(decoration());
    if (!d) {
        return QColor();
    }

    static const QColor s_hoverColor(QStringLiteral("#3d3e3f"));

    if (isPressed()) {
        return s_hoverColor.darker(115);
    } else if (m_opacity > 0.0) {
        QColor color(s_hoverColor);
        color.setAlphaF(m_opacity);
        return color;
    } else {
        return QColor();
    }
}

//________________________________________________________________
void Button::reconfigure()
{
    auto d = qobject_cast<Decoration *>(decoration());
    if (!d) {
        return;
    }

    const qreal scale = d->effectiveScale();

    switch (type()) {
    case KDecoration3::DecorationButtonType::Menu: {
        const qreal appIconSize = KDecoration3::snapToPixelGrid(25.0 / scale, scale);
        setPreferredSize(QSizeF(appIconSize, appIconSize));
        setGeometry(QRectF(geometry().topLeft(), QSizeF(appIconSize, appIconSize)));
        break;
    }
    case KDecoration3::DecorationButtonType::Close:
    case KDecoration3::DecorationButtonType::Maximize:
    case KDecoration3::DecorationButtonType::Minimize: {
        const qreal btnW = KDecoration3::snapToPixelGrid(34.0 / scale, scale);
        const qreal btnH = KDecoration3::snapToPixelGrid(45.0 / scale, scale);
        setPreferredSize(QSizeF(btnW, btnH));
        setGeometry(QRectF(geometry().topLeft(), QSizeF(btnW, btnH)));
        break;
    }
    default:
        setPreferredSize(QSizeF(d->buttonSize(), d->buttonSize()));
        break;
    }

    m_animation->setDuration(150);
    m_animation->setEasingCurve(QEasingCurve::OutCubic);
}

//__________________________________________________________________
void Button::updateAnimationState(bool hovered)
{
    m_animation->setDirection(hovered ? QAbstractAnimation::Forward : QAbstractAnimation::Backward);
    if (m_animation->state() != QAbstractAnimation::Running) {
        m_animation->start();
    }
}

} // namespace DoodlebookOS

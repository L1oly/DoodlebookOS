/*
 * SPDX-FileCopyrightText: 2014 Hugo Pereira Da Costa <hugo.pereira@free.fr>
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "helper.h"

#include "doodlebookos.h"
#include "propertynames.h"

#include <KColorScheme>
#include <KColorUtils>
#include <KIconLoader>
#include <KWindowSystem>
#include <qobject.h>
#if __has_include(<KX11Extras>)
#include <KX11Extras>
#endif

#include <QApplication>
#include <QDockWidget>
#include <QFileInfo>
#include <QMainWindow>
#include <QMdiArea>
#include <QMenuBar>
#include <QPainter>
#include <QStyleOption>
#include <QTreeView>
#include <QWindow>

#include <QDialog>
#include <algorithm>

namespace DoodlebookOS
{
//* contrast for arrow and treeline rendering
static const qreal arrowShade = 0.15;

static const qreal highlightBackgroundAlpha = Metrics::Blend_Value;

static const auto radioCheckSunkenDarkeningFactor = 110;

PaletteChangedEventFilter::PaletteChangedEventFilter(Helper *helper)
    : QObject(helper)
    , _helper(helper)
{
}

bool PaletteChangedEventFilter::eventFilter(QObject *watched, QEvent *event)
{
    if (event->type() != QEvent::ApplicationPaletteChange || watched != qApp) {
        return QObject::eventFilter(watched, event);
    }
    if (!qApp->property("KDE_COLOR_SCHEME_PATH").isValid()) {
        return QObject::eventFilter(watched, event);
    }
    const auto path = qApp->property("KDE_COLOR_SCHEME_PATH").toString();
    if (!path.isEmpty()) {
        KConfig config(path, KConfig::SimpleConfig);
        KConfigGroup group(config.group(QStringLiteral("WM")));
        const QPalette palette(QApplication::palette());
        _helper->_activeTitleBarColor = group.readEntry("activeBackground", palette.color(QPalette::Active, QPalette::Highlight));
        _helper->_activeTitleBarTextColor = group.readEntry("activeForeground", palette.color(QPalette::Active, QPalette::HighlightedText));
        _helper->_inactiveTitleBarColor = group.readEntry("inactiveBackground", palette.color(QPalette::Disabled, QPalette::Highlight));
        _helper->_inactiveTitleBarTextColor = group.readEntry("inactiveForeground", palette.color(QPalette::Disabled, QPalette::HighlightedText));
    }
    return QObject::eventFilter(watched, event);
}

//____________________________________________________________________
Helper::Helper(KSharedConfig::Ptr config)
    : QObject()
    , _config(std::move(config))
    , _kwinConfig(KSharedConfig::openConfig(QStringLiteral("kwinrc")))
    , _eventFilter(new PaletteChangedEventFilter(this))
{
}

//____________________________________________________________________
KSharedConfig::Ptr Helper::config() const
{
    return _config;
}

//____________________________________________________________________
void Helper::loadConfig()
{
    _viewFocusBrush = KStatefulBrush(KColorScheme::View, KColorScheme::FocusColor);
    _viewHoverBrush = KStatefulBrush(KColorScheme::View, KColorScheme::HoverColor);
    _viewNegativeTextBrush = KStatefulBrush(KColorScheme::View, KColorScheme::NegativeText);
    _viewNeutralTextBrush = KStatefulBrush(KColorScheme::View, KColorScheme::NeutralText);

    const QPalette palette(QApplication::palette());
    _config->reparseConfiguration();
    _kwinConfig->reparseConfiguration();
    _cachedAutoValid = false;

    KConfigGroup globalGroup(_config->group(QStringLiteral("WM")));
    _activeTitleBarColor = globalGroup.readEntry("activeBackground", palette.color(QPalette::Active, QPalette::Highlight));
    _activeTitleBarTextColor = globalGroup.readEntry("activeForeground", palette.color(QPalette::Active, QPalette::HighlightedText));
    _inactiveTitleBarColor = globalGroup.readEntry("inactiveBackground", palette.color(QPalette::Disabled, QPalette::Highlight));
    _inactiveTitleBarTextColor = globalGroup.readEntry("inactiveForeground", palette.color(QPalette::Disabled, QPalette::HighlightedText));
    _contrastBias = 0.0;

    if (const QString colorSchemePath = qApp->property("KDE_COLOR_SCHEME_PATH").toString(); !colorSchemePath.isEmpty()) {
        KConfig config(colorSchemePath, KConfig::SimpleConfig);
        KConfigGroup appGroup(config.group(QStringLiteral("WM")));
        _activeTitleBarColor = appGroup.readEntry("activeBackground", _activeTitleBarColor);
        _activeTitleBarTextColor = appGroup.readEntry("activeForeground", _activeTitleBarTextColor);
        _inactiveTitleBarColor = appGroup.readEntry("inactiveBackground", _inactiveTitleBarColor);
        _inactiveTitleBarTextColor = appGroup.readEntry("inactiveForeground", _inactiveTitleBarTextColor);
    }
}

void Helper::installEventFilter(QApplication *app) const
{
    if (app) {
        app->installEventFilter(_eventFilter);
    }
}

void Helper::removeEventFilter(QApplication *app) const
{
    if (app) {
        app->removeEventFilter(_eventFilter);
    }
}

QColor transparentize(const QColor &color, qreal amount)
{
    auto clone = color;
    clone.setAlphaF(amount);
    return clone;
}

//____________________________________________________________________
QColor Helper::frameOutlineColor(const QPalette &palette, bool mouseOver, bool hasFocus, qreal opacity, AnimationMode mode) const
{
    QColor outline(KColorUtils::mix(palette.color(QPalette::Window), palette.color(QPalette::WindowText), frameIntensityBias()));

    // focus takes precedence over hover
    if (mode == AnimationFocus) {
        const QColor focus(focusColor(palette));
        const QColor hover(hoverColor(palette));

        if (mouseOver) {
            outline = KColorUtils::mix(hover, focus, opacity);
        } else {
            outline = KColorUtils::mix(outline, focus, opacity);
        }

    } else if (hasFocus) {
        outline = focusColor(palette);

    } else if (mode == AnimationHover) {
        const QColor hover(hoverColor(palette));
        outline = KColorUtils::mix(outline, hover, opacity);

    } else if (mouseOver) {
        outline = hoverColor(palette);
    }

    return outline;
}

//____________________________________________________________________
QColor Helper::focusOutlineColor(const QPalette &palette) const
{
    return KColorUtils::mix(focusColor(palette), palette.color(QPalette::WindowText), 0.15);
}

//____________________________________________________________________
QColor Helper::hoverOutlineColor(const QPalette &palette) const
{
    return KColorUtils::mix(hoverColor(palette), palette.color(QPalette::WindowText), 0.15);
}

//____________________________________________________________________
QColor Helper::sidePanelOutlineColor(const QPalette &palette, bool hasFocus, qreal opacity, AnimationMode mode) const
{
    QColor outline(palette.color(QPalette::Inactive, QPalette::Highlight));
    const QColor &focus = palette.color(QPalette::Active, QPalette::Highlight);

    if (mode == AnimationFocus) {
        outline = KColorUtils::mix(outline, focus, opacity);

    } else if (hasFocus) {
        outline = focus;
    }

    return outline;
}

//____________________________________________________________________
QColor Helper::frameBackgroundColor(const QPalette &palette, QPalette::ColorGroup group) const
{
    return KColorUtils::mix(palette.color(group, QPalette::Window), palette.color(group, QPalette::Base), Metrics::Blend_Value);
}

//____________________________________________________________________
QColor Helper::arrowColor(const QPalette &palette, QPalette::ColorGroup group, QPalette::ColorRole role) const
{
    switch (role) {
    case QPalette::Text:
        return KColorUtils::mix(palette.color(group, QPalette::Text), palette.color(group, QPalette::Base), arrowShade);
    case QPalette::WindowText:
        return KColorUtils::mix(palette.color(group, QPalette::WindowText), palette.color(group, QPalette::Window), arrowShade);
    case QPalette::ButtonText:
        return KColorUtils::mix(palette.color(group, QPalette::ButtonText), palette.color(group, QPalette::Button), arrowShade);
    default:
        return palette.color(group, role);
    }
}

//____________________________________________________________________
QColor Helper::arrowColor(const QPalette &palette, bool mouseOver, bool hasFocus, qreal opacity, AnimationMode mode) const
{
    QColor outline(arrowColor(palette, QPalette::WindowText));
    if (mode == AnimationHover) {
        const QColor focus(focusColor(palette));
        const QColor hover(hoverColor(palette));
        if (hasFocus) {
            outline = KColorUtils::mix(focus, hover, opacity);
        } else {
            outline = KColorUtils::mix(outline, hover, opacity);
        }

    } else if (mouseOver) {
        outline = hoverColor(palette);

    } else if (mode == AnimationFocus) {
        const QColor focus(focusColor(palette));
        outline = KColorUtils::mix(outline, focus, opacity);

    } else if (hasFocus) {
        outline = focusColor(palette);
    }

    return outline;
}

//____________________________________________________________________
QColor Helper::sliderOutlineColor(const QPalette &palette, bool mouseOver, bool hasFocus, qreal opacity, AnimationMode mode) const
{
    QColor outline(KColorUtils::mix(palette.color(QPalette::Button), palette.color(QPalette::ButtonText), frameIntensityBias()));

    // hover takes precedence over focus
    if (mode == AnimationHover) {
        const QColor hover(hoverColor(palette));
        const QColor focus(focusColor(palette));
        if (hasFocus) {
            outline = KColorUtils::mix(focus, hover, opacity);
        } else {
            outline = KColorUtils::mix(outline, hover, opacity);
        }

    } else if (mouseOver) {
        outline = hoverColor(palette);

    } else if (mode == AnimationFocus) {
        const QColor focus(focusColor(palette));
        outline = KColorUtils::mix(outline, focus, opacity);

    } else if (hasFocus) {
        outline = focusColor(palette);
    }

    return outline;
}

//____________________________________________________________________
QColor Helper::scrollBarHandleColor(const QPalette &palette, bool mouseOver, bool hasFocus, qreal opacity, AnimationMode mode) const
{
    QColor color(alphaColor(palette.color(QPalette::WindowText), 0.5));

    // hover takes precedence over focus
    if (mode == AnimationHover) {
        const QColor hover(hoverColor(palette));
        const QColor focus(focusColor(palette));
        if (hasFocus) {
            color = KColorUtils::mix(focus, hover, opacity);
        } else {
            color = KColorUtils::mix(color, hover, opacity);
        }

    } else if (mouseOver) {
        color = hoverColor(palette);

    } else if (mode == AnimationFocus) {
        const QColor focus(focusColor(palette));
        color = KColorUtils::mix(color, focus, opacity);

    } else if (hasFocus) {
        color = focusColor(palette);
    }

    return color;
}

//______________________________________________________________________________
QColor Helper::checkBoxIndicatorColor(const QPalette &palette, bool mouseOver, bool active, qreal opacity, AnimationMode mode) const
{
    QColor color(KColorUtils::mix(palette.color(QPalette::Window), palette.color(QPalette::WindowText), 0.6));
    if (mode == AnimationHover) {
        const QColor focus(focusColor(palette));
        const QColor hover(hoverColor(palette));
        if (active) {
            color = KColorUtils::mix(focus, hover, opacity);
        } else {
            color = KColorUtils::mix(color, hover, opacity);
        }

    } else if (mouseOver) {
        color = hoverColor(palette);

    } else if (active) {
        color = focusColor(palette);
    }

    return color;
}

//______________________________________________________________________________
QColor Helper::separatorColor(const QPalette &palette) const
{
    return KColorUtils::mix(palette.color(QPalette::Window), palette.color(QPalette::WindowText), frameIntensityBias());
}

//______________________________________________________________________________
QPalette Helper::disabledPalette(const QPalette &source, qreal ratio) const
{
    QPalette copy(source);

    const QList<QPalette::ColorRole> roles =
        {QPalette::Window, QPalette::Highlight, QPalette::WindowText, QPalette::ButtonText, QPalette::Text, QPalette::Button};
    for (const QPalette::ColorRole &role : roles) {
        copy.setColor(role, KColorUtils::mix(source.color(QPalette::Active, role), source.color(QPalette::Disabled, role), 1.0 - ratio));
    }

    return copy;
}

//____________________________________________________________________
QColor Helper::alphaColor(QColor color, qreal alpha) const
{
    if (alpha >= 0 && alpha < 1.0) {
        color.setAlphaF(alpha * color.alphaF());
    }
    return color;
}

//______________________________________________________________________________
void Helper::renderDebugFrame(QPainter *painter, const QRectF &rect) const
{
    painter->save();
    painter->setRenderHints(QPainter::Antialiasing);
    painter->setBrush(Qt::NoBrush);
    painter->setPen(Qt::red);
    painter->drawRect(strokedRect(rect));
    painter->restore();
}

//______________________________________________________________________________
void Helper::renderFocusRect(QPainter *painter, const QRectF &rect, const QBrush &brush, const QColor &outline, Sides sides) const
{
    painter->save();
    painter->setRenderHints(QPainter::Antialiasing);
    painter->setBrush(brush);

    if (!(outline.isValid() && sides)) {
        painter->setPen(Qt::NoPen);
        painter->drawRect(rect);

    } else {
        painter->setClipRect(rect);

        QRectF copy(strokedRect(rect));

        const qreal radius(frameRadius(PenWidth::Frame));
        if (!(sides & SideTop)) {
            copy.adjust(0, -radius, 0, 0);
        }
        if (!(sides & SideBottom)) {
            copy.adjust(0, 0, 0, radius);
        }
        if (!(sides & SideLeft)) {
            copy.adjust(-radius, 0, 0, 0);
        }
        if (!(sides & SideRight)) {
            copy.adjust(0, 0, radius, 0);
        }

        painter->setPen(outline);
        // painter->setBrush( Qt::NoBrush );
        painter->drawRoundedRect(copy, radius, radius);
    }

    painter->restore();
}

//______________________________________________________________________________
void Helper::renderFocusLine(QPainter *painter, const QRectF &rect, const QColor &color) const
{
    if (!color.isValid()) {
        return;
    }

    painter->save();
    painter->setRenderHint(QPainter::Antialiasing, false);
    painter->setBrush(Qt::NoBrush);
    painter->setPen(color);

    painter->translate(0, 2);
    painter->drawLine(rect.bottomLeft(), rect.bottomRight());
    painter->restore();
}

//______________________________________________________________________________
void Helper::renderFrameWithSides(QPainter *painter, const QRectF &rect, const QColor &color, Qt::Edges edges, const QColor &outline) const
{
    painter->save();

    painter->setRenderHint(QPainter::Antialiasing);

    QRectF frameRect(rect);

    // set brush
    painter->setBrush(color);
    painter->setPen(Qt::NoPen);

    // render
    painter->drawRect(frameRect);

    // set brush again
    painter->setBrush(Qt::NoBrush);
    painter->setPen(outline);

    // manually apply the effects of StrokedRect here but only to the edges with a frame
    if (edges & Qt::LeftEdge) {
        frameRect.adjust(0.5, 0.0, 0.0, 0.0);
    }
    if (edges & Qt::RightEdge) {
        frameRect.adjust(0.0, 0, -0.5, 0.0);
    }
    if (edges & Qt::TopEdge) {
        frameRect.adjust(0.0, 0.5, 0.0, 0.0);
    }
    if (edges & Qt::BottomEdge) {
        frameRect.adjust(0.0, 0.0, 0.0, -0.5);
    }

    // draw lines
    if (edges & Qt::LeftEdge) {
        painter->drawLine(QLineF(frameRect.topLeft(), frameRect.bottomLeft()));
    }
    if (edges & Qt::RightEdge) {
        painter->drawLine(QLineF(frameRect.topRight(), frameRect.bottomRight()));
    }
    if (edges & Qt::TopEdge) {
        painter->drawLine(QLineF(frameRect.topLeft(), frameRect.topRight()));
    }
    if (edges & Qt::BottomEdge) {
        painter->drawLine(QLineF(frameRect.bottomLeft(), frameRect.bottomRight()));
    }

    painter->restore();
}

//______________________________________________________________________________
void Helper::renderFrame(QPainter *painter, const QRectF &rect, const QColor &color, const QColor &outline) const
{
    painter->setRenderHint(QPainter::Antialiasing);

    QRectF frameRect(rect);
    qreal radius(frameRadius(PenWidth::NoPen));

    // set pen
    if (outline.isValid()) {
        painter->setPen(outline);
        frameRect = strokedRect(frameRect);
        radius = frameRadiusForNewPenWidth(radius, PenWidth::Frame);

    } else {
        painter->setPen(Qt::NoPen);
    }

    // set brush
    if (color.isValid()) {
        painter->setBrush(color);
    } else {
        painter->setBrush(Qt::NoBrush);
    }

    // render
    painter->drawRoundedRect(frameRect, radius, radius);
}

//______________________________________________________________________________
void Helper::renderSidePanelFrame(QPainter *painter, const QRectF &rect, const QColor &outline, Side side) const
{
    // In DOSTEST2 side panel is completely flat/seamless against the main view
    Q_UNUSED(painter);
    Q_UNUSED(rect);
    Q_UNUSED(outline);
    Q_UNUSED(side);
    return;
}

//______________________________________________________________________________
void Helper::renderMenuFrame(QPainter *painter, const QRectF &rect, const QColor &color, const QColor &outline, bool roundCorners, Qt::Edges seamlessEdges)
    const
{
    painter->save();

    // set brush
    if (color.isValid()) {
        painter->setBrush(color);
    } else {
        painter->setBrush(Qt::NoBrush);
    }

    // We simulate being able to independently adjust corner radii by
    // setting a clip region and then extending the rectangle beyond it.
    if (seamlessEdges != Qt::Edges()) {
        painter->setClipRect(rect);
    }

    if (roundCorners) {
        painter->setRenderHint(QPainter::Antialiasing);
        QRectF frameRect(rect);

        qreal radius(Metrics::Menu_FrameRadius);

        frameRect.adjust( //
            seamlessEdges.testFlag(Qt::LeftEdge) ? -radius : 0,
            seamlessEdges.testFlag(Qt::TopEdge) ? -radius : 0,
            seamlessEdges.testFlag(Qt::RightEdge) ? radius : 0,
            seamlessEdges.testFlag(Qt::BottomEdge) ? radius : 0);

        // set pen
        if (outline.isValid()) {
            painter->setPen(outline);
            frameRect = strokedRect(frameRect);
            radius = frameRadiusForNewPenWidth(radius, PenWidth::Frame);

        } else {
            painter->setPen(Qt::NoPen);
        }

        // render
        painter->drawRoundedRect(frameRect, radius, radius);

    } else {
        painter->setRenderHint(QPainter::Antialiasing, false);
        QRectF frameRect(rect);

        frameRect.adjust( //
            seamlessEdges.testFlag(Qt::LeftEdge) ? 1 : 0,
            seamlessEdges.testFlag(Qt::TopEdge) ? 1 : 0,
            seamlessEdges.testFlag(Qt::RightEdge) ? -1 : 0,
            seamlessEdges.testFlag(Qt::BottomEdge) ? -1 : 0);

        if (outline.isValid()) {
            painter->setPen(outline);
            frameRect.adjust(0, 0, -1, -1);

        } else {
            painter->setPen(Qt::NoPen);
        }

        painter->drawRect(frameRect);
    }

    painter->restore();
}

QRegion Helper::menuFrameRegion(const QMenu *widget)
{
    if (!widget) {
        return {};
    }

    const bool hasAlpha(hasAlphaChannel(widget));
    const auto seamlessEdges = menuSeamlessEdges(widget);
    const auto roundCorners = hasAlpha;

    if (roundCorners) {
        QRectF frameRect(widget->rect());

        qreal radius(Metrics::Menu_FrameRadius);

        frameRect.adjust( //
            seamlessEdges.testFlag(Qt::LeftEdge) ? -radius : 0,
            seamlessEdges.testFlag(Qt::TopEdge) ? -radius : 0,
            seamlessEdges.testFlag(Qt::RightEdge) ? radius : 0,
            seamlessEdges.testFlag(Qt::BottomEdge) ? radius : 0);

        // outline is always valid/drawn
        frameRect = strokedRect(frameRect);
        radius = frameRadiusForNewPenWidth(radius, PenWidth::Frame);

        QPainterPath path;
        path.addRoundedRect(frameRect, radius, radius);
        return QRegion(path.toFillPolygon().toPolygon()).intersected(widget->rect());
    }

    return QRegion(widget->rect());
}

//______________________________________________________________________________
void Helper::renderButtonFrame(QPainter *painter,
                               const QRectF &rect,
                               const QPalette &palette,
                               const QHash<QByteArray, bool> &stateProperties,
                               qreal bgAnimation,
                               qreal penAnimation) const
{
    bool enabled = stateProperties.value("enabled", true);
    bool visualFocus = stateProperties.value("visualFocus");
    bool hovered = stateProperties.value("hovered");
    bool down = stateProperties.value("down");
    bool checked = stateProperties.value("checked");
    bool flat = stateProperties.value("flat");
    bool defaultButton = stateProperties.value("defaultButton");
    bool hasNeutralHighlight = stateProperties.value("hasNeutralHighlight");
    bool isActiveWindow = stateProperties.value("isActiveWindow");
    const bool roundButton = stateProperties.value("roundButton");

    // don't render background if flat and not hovered, down, checked, or given visual focus
    if (flat && !(hovered || down || checked || visualFocus) && bgAnimation == AnimationData::OpacityInvalid && penAnimation == AnimationData::OpacityInvalid) {
        return;
    }

    QRectF shadowedRect = this->shadowedRect(rect);
    QRectF frameRect = strokedRect(shadowedRect);
    // setting color group to work around KColorScheme feature
    const QColor &highlightColor = palette.color(!enabled ? QPalette::Disabled : QPalette::Active, QPalette::Highlight);
    QBrush bgBrush;
    QBrush penBrush;

    // Colors
    if (flat) {
        if (down && enabled) {
            bgBrush = alphaColor(highlightColor, 0.25);
            penBrush = Qt::NoBrush;
        } else if (checked) {
            bgBrush = alphaColor(highlightColor, 0.30);
            penBrush = Qt::NoBrush;
        } else if ((hovered || visualFocus) && enabled) {
            bgBrush = alphaColor(highlightColor, 0.15);
            penBrush = Qt::NoBrush;
        } else if (isActiveWindow && defaultButton) {
            bgBrush = alphaColor(highlightColor, 0.125);
            penBrush = Qt::NoBrush;
        } else {
            bgBrush = Qt::NoBrush;
            penBrush = Qt::NoBrush;
        }
    } else {
        if (down && enabled) {
            bgBrush = KColorUtils::mix(palette.button().color(), highlightColor, Metrics::Blend_Value);
        } else if (checked) {
            bgBrush = hasNeutralHighlight ? KColorUtils::mix(palette.button().color(), neutralText(palette), Metrics::Blend_Value)
                                          : KColorUtils::mix(palette.button().color(), palette.buttonText().color(), 0.125);
            penBrush =
                hasNeutralHighlight ? neutralText(palette) : KColorUtils::mix(palette.button().color(), palette.buttonText().color(), frameIntensityBias());
        } else if (isActiveWindow && defaultButton) {
            if (down && enabled) {
                bgBrush = KColorUtils::darken(highlightColor, 0.1);
            } else if ((hovered || visualFocus) && enabled) {
                bgBrush = KColorUtils::lighten(highlightColor, 0.08);
            } else {
                bgBrush = highlightColor;
            }
            penBrush = bgBrush;
        } else {
            // Material 3 Filled Tonal Button (standard non-primary button without outline)
            if (down && enabled) {
                bgBrush = KColorUtils::mix(palette.button().color(), highlightColor, 0.25);
            } else if ((hovered || visualFocus) && enabled) {
                bgBrush = KColorUtils::mix(palette.button().color(), highlightColor, 0.12);
            } else {
                bgBrush = palette.button().color();
            }
            penBrush = Qt::NoBrush; // no outline/contour
        }
    }

    if ((hovered || visualFocus || down) && enabled && defaultButton && !flat) {
        penBrush = highlightColor;
    }

    // Animations
    if (bgAnimation != AnimationData::OpacityInvalid && enabled) {
        QColor color1 = bgBrush.color();
        QColor color2 =
            flat ? alphaColor(highlightColor, 0.20) : KColorUtils::mix(palette.button().color(), highlightColor, Metrics::Blend_Value);
        bgBrush = KColorUtils::mix(color1, color2, bgAnimation);
    }
    if (penAnimation != AnimationData::OpacityInvalid && enabled) {
        if (flat) {
            bgBrush = alphaColor(highlightColor, 0.15 * penAnimation);
            penBrush = Qt::NoBrush;
        } else {
            QColor color1 = penBrush.color();
            QColor color2 = highlightColor;
            penBrush = KColorUtils::mix(color1, color2, penAnimation);
        }
    }

    const qreal roundRadius = std::max(rect.width(), rect.height()) / 2;
    // Shadow
    if (isActiveWindow && !(flat || down || checked) && enabled) {
        const qreal shadowRadius = roundButton ? roundRadius : (shadowedRect.height() / 2.0);
        renderRoundedRectShadow(painter, shadowedRect, shadowColor(palette), shadowRadius);
    }

    // Render button
    painter->setRenderHint(QPainter::Antialiasing, true);
    painter->setBrush(bgBrush);
    painter->setPen(flat ? QPen(Qt::NoPen) : QPen(penBrush, PenWidth::Frame));
    const qreal pillRadius = frameRect.height() / 2.0;
    const qreal radius = roundButton ? roundRadius : pillRadius;
    painter->drawRoundedRect(frameRect, radius, radius);
}

//______________________________________________________________________________
void Helper::renderToolBoxFrame(QPainter *painter, const QRectF &rect, int tabWidth, const QColor &outline) const
{
    if (!outline.isValid()) {
        return;
    }

    // round radius
    const qreal radius(frameRadius(PenWidth::Frame));
    const QSizeF cornerSize(2 * radius, 2 * radius);

    // if rect - tabwidth is even, need to increase tabWidth by 1 unit
    // for anti aliasing
    if (!((rect.toRect().width() - tabWidth) % 2)) {
        ++tabWidth;
    }

    // adjust rect for antialiasing
    QRectF baseRect(strokedRect(rect));

    // create path
    QPainterPath path;
    path.moveTo(0, baseRect.height() - 1);
    path.lineTo((baseRect.width() - tabWidth) / 2 - radius, baseRect.height() - 1);
    path.arcTo(QRectF(QPointF((baseRect.width() - tabWidth) / 2 - 2 * radius, baseRect.height() - 1 - 2 * radius), cornerSize), 270, 90);
    path.lineTo((baseRect.width() - tabWidth) / 2, radius);
    path.arcTo(QRectF(QPointF((baseRect.width() - tabWidth) / 2, 0), cornerSize), 180, -90);
    path.lineTo((baseRect.width() + tabWidth) / 2 - 1 - radius, 0);
    path.arcTo(QRectF(QPointF((baseRect.width() + tabWidth) / 2 - 1 - 2 * radius, 0), cornerSize), 90, -90);
    path.lineTo((baseRect.width() + tabWidth) / 2 - 1, baseRect.height() - 1 - radius);
    path.arcTo(QRectF(QPointF((baseRect.width() + tabWidth) / 2 - 1, baseRect.height() - 1 - 2 * radius), cornerSize), 180, 90);
    path.lineTo(baseRect.width() - 1, baseRect.height() - 1);

    // render
    painter->setRenderHints(QPainter::Antialiasing);
    painter->setBrush(Qt::NoBrush);
    painter->setPen(outline);
    painter->translate(baseRect.topLeft());
    painter->drawPath(path);
}

//______________________________________________________________________________
void Helper::renderTabWidgetFrame(QPainter *painter, const QRectF &rect, const QColor &color, const QColor &outline, Corners corners) const
{
    painter->setRenderHint(QPainter::Antialiasing);

    QRectF frameRect(rect.adjusted(1, 1, -1, -1));
    qreal radius(frameRadius(PenWidth::NoPen));

    // set pen
    if (outline.isValid()) {
        painter->setPen(outline);
        frameRect = strokedRect(frameRect);
        radius = frameRadiusForNewPenWidth(radius, PenWidth::Frame);

    } else {
        painter->setPen(Qt::NoPen);
    }

    // set brush
    if (color.isValid()) {
        painter->setBrush(color);
    } else {
        painter->setBrush(Qt::NoBrush);
    }

    // render
    QPainterPath path(roundedPath(frameRect, corners, radius));
    painter->drawPath(path);
}

//______________________________________________________________________________
void Helper::renderSeparator(QPainter *painter, const QRectF &rect, const QColor &color, bool vertical) const
{
    painter->setRenderHint(QPainter::Antialiasing, false);
    painter->setBrush(Qt::NoBrush);
    painter->setPen(color);

    if (vertical) {
        painter->translate(rect.width() / 2, 0);
        painter->drawLine(rect.topLeft(), rect.bottomLeft());

    } else {
        painter->translate(0, rect.height() / 2);
        painter->drawLine(rect.topLeft(), rect.topRight());
    }
}

//______________________________________________________________________________
void Helper::renderCheckBoxBackground(QPainter *painter,
                                      const QRectF &rect,
                                      const QPalette &palette,
                                      CheckBoxState state,
                                      bool neutalHighlight,
                                      bool sunken,
                                      qreal animation) const
{
    // setup painter
    painter->setRenderHint(QPainter::Antialiasing, true);

    // Kapsułkowa szyna switcha Material 3 Expressive
    QRectF trackRect(rect);
    trackRect.adjust(1.5, 1.5, -1.5, -1.5);
    const qreal trackRadius = trackRect.height() / 2.0;

    const QColor primaryColor = palette.highlight().color();
    const QColor inactiveBorder = neutalHighlight ? neutralText(palette) : separatorColor(palette);
    const QColor inactiveBg = palette.button().color().darker(sunken ? radioCheckSunkenDarkeningFactor : 100);

    qreal progress = 0.0;
    if (state == CheckOn) progress = 1.0;
    else if (state == CheckOff) progress = 0.0;
    else if (state == CheckPartial) progress = 0.5;
    else if (state == CheckAnimated) progress = animation;

    QColor currentBg = KColorUtils::mix(inactiveBg, primaryColor, progress);
    QColor currentBorder = KColorUtils::mix(inactiveBorder, primaryColor, progress);

    painter->setPen(QPen(currentBorder, 1.5));
    painter->setBrush(currentBg);
    painter->drawRoundedRect(trackRect, trackRadius, trackRadius);
}

//______________________________________________________________________________
void Helper::renderCheckBox(QPainter *painter,
                            const QRectF &rect,
                            const QPalette &palette,
                            bool mouseOver,
                            CheckBoxState state,
                            CheckBoxState target,
                            bool neutalHighlight,
                            bool sunken,
                            qreal animation,
                            qreal hoverAnimation) const
{
    Q_UNUSED(sunken)
    Q_UNUSED(neutalHighlight)
    Q_UNUSED(hoverAnimation)

    // setup painter
    painter->setRenderHint(QPainter::Antialiasing, true);

    QRectF trackRect(rect);
    trackRect.adjust(1.5, 1.5, -1.5, -1.5);

    // Oblicz postęp animacji przesunięcia gałki (0.0 = wyłączony po lewej, 1.0 = włączony po prawej)
    qreal progress = 0.0;
    if (state == CheckOn) {
        progress = 1.0;
    } else if (state == CheckOff) {
        progress = 0.0;
    } else if (state == CheckPartial) {
        progress = 0.5;
    } else if (state == CheckAnimated) {
        progress = (target == CheckOn) ? animation : (1.0 - animation);
    }

    // Material 3: Gałka powiększa się z 10px (nieaktywna) do 15px (aktywna)
    const qreal thumbDiameter = 10.0 + 5.0 * progress;
    const qreal thumbRadius = thumbDiameter / 2.0;

    const qreal minX = trackRect.left() + 2.5 + 7.5;
    const qreal maxX = trackRect.right() - 2.5 - 7.5;
    const qreal centerX = minX + progress * (maxX - minX);
    const qreal centerY = trackRect.center().y();

    // Kolor gałki (nieaktywna = neutralny tekst, aktywna = onPrimary #374062)
    const QColor inactiveThumb = palette.buttonText().color();
    const QColor activeThumb = palette.highlightedText().color();
    const QColor thumbColor = KColorUtils::mix(inactiveThumb, activeThumb, progress);

    // Rysowanie gałki (Thumb)
    painter->setPen(Qt::NoPen);
    painter->setBrush(thumbColor);
    painter->drawEllipse(QPointF(centerX, centerY), thumbRadius, thumbRadius);

    // Ptaszek wewnątrz gałki w kolorze Primary (Material 3 Expressive)
    if (progress > 0.1) {
        painter->save();
        painter->setOpacity(progress);

        const QColor checkmarkColor = palette.highlight().color();
        QPen checkPen(checkmarkColor, 1.8);
        checkPen.setCapStyle(Qt::RoundCap);
        checkPen.setJoinStyle(Qt::RoundJoin);
        painter->setPen(checkPen);
        painter->setBrush(Qt::NoBrush);

        QPainterPath checkPath;
        checkPath.moveTo(centerX - 3.2, centerY);
        checkPath.lineTo(centerX - 0.8, centerY + 2.3);
        checkPath.lineTo(centerX + 3.2, centerY - 2.1);
        painter->drawPath(checkPath);

        painter->restore();
    }
}

//______________________________________________________________________________
void Helper::renderRadioButtonBackground(QPainter *painter,
                                         const QRectF &rect,
                                         const QPalette &palette,
                                         RadioButtonState state,
                                         bool neutalHighlight,
                                         bool sunken,
                                         qreal animation) const
{
    Q_UNUSED(sunken);

    // setup painter
    painter->setRenderHint(QPainter::Antialiasing, true);

    // copy rect - zwięzły pierścień 16x16 z zachowaniem proporcji
    QRectF frameRect(rect);
    frameRect.adjust(2.2, 2.2, -2.2, -2.2);

    const QColor primaryColor = palette.highlight().color();
    const QColor borderColor = neutalHighlight ? neutralText(palette) : (state == RadioOn ? primaryColor : separatorColor(palette));

    // Zewnętrzny pierścień bez wypełnienia (środek w 100% w kolorze tła powierzchni)
    painter->setPen(QPen(borderColor, 1.8));
    painter->setBrush(Qt::NoBrush);
    painter->drawEllipse(frameRect);

    if (state == RadioAnimated) {
        QColor animatedBorder = KColorUtils::mix(separatorColor(palette), primaryColor, animation);
        painter->setPen(QPen(animatedBorder, 1.8));
        painter->setBrush(Qt::NoBrush);
        painter->drawEllipse(frameRect);
    }
}

//______________________________________________________________________________
void Helper::renderRadioButton(QPainter *painter,
                               const QRectF &rect,
                               const QPalette &palette,
                               bool mouseOver,
                               RadioButtonState state,
                               bool neutralHighlight,
                               bool sunken,
                               qreal animation,
                               qreal animationHover) const
{
    Q_UNUSED(sunken)

    // setup painter
    painter->setRenderHint(QPainter::Antialiasing, true);

    // copy rect
    QRectF frameRect(rect);
    frameRect.adjust(1, 1, -1, -1);

    if (mouseOver) {
        painter->save();

        if (animationHover != AnimationData::OpacityInvalid) {
            painter->setOpacity(animationHover);
        }

        painter->setPen(QPen(neutralHighlight ? neutralText(palette).lighter() : focusColor(palette), PenWidth::Frame));
        painter->setBrush(Qt::NoBrush);

        const QRectF contentRect(frameRect.adjusted(1, 1, -1, -1).adjusted(0.5, 0.5, -0.5, -0.5));
        painter->drawEllipse(contentRect);

        painter->restore();
    }

    const QColor primaryColor = palette.highlight().color();
    painter->setBrush(primaryColor);
    painter->setPen(Qt::NoPen);

    // Kropka wewnętrzna o idealnych proporcjach ze wzorca (promień 3.6 px)
    const qreal radius = 3.6;
    const QPointF center = frameRect.center();

    // mark
    switch (state) {
    case RadioOn:
        painter->drawEllipse(center, radius, radius);
        break;
    case RadioAnimated: {
        const qreal animationRadius = radius * animation;
        painter->drawEllipse(center, animationRadius, animationRadius);
        break;
    }
    default:
        break;
    }
}

//______________________________________________________________________________
void Helper::renderSliderGroove(QPainter *painter, const QRectF &rect, const QColor &fg, const QColor &bg, qreal rLeft, qreal rRight) const
{
    // setup painter
    painter->setRenderHint(QPainter::Antialiasing, true);

    const QRectF baseRect(rect);
    const qreal maxRadius = 0.5 * qMin(baseRect.width(), baseRect.height());
    const qreal rl = qMin(rLeft, maxRadius);
    const qreal rr = qMin(rRight, maxRadius);

    if (fg.isValid()) {
        painter->setPen(Qt::NoPen);
        painter->setBrush(fg);

        if (qFuzzyCompare(rl, rr)) {
            painter->drawRoundedRect(baseRect, rl, rl);
        } else {
            // Draw rounded rect with asymmetric corner radii
            QPainterPath path;
            path.moveTo(baseRect.left() + rl, baseRect.top());
            path.lineTo(baseRect.right() - rr, baseRect.top());
            path.quadTo(baseRect.right(), baseRect.top(), baseRect.right(), baseRect.top() + rr);
            path.lineTo(baseRect.right(), baseRect.bottom() - rr);
            path.quadTo(baseRect.right(), baseRect.bottom(), baseRect.right() - rr, baseRect.bottom());
            path.lineTo(baseRect.left() + rl, baseRect.bottom());
            path.quadTo(baseRect.left(), baseRect.bottom(), baseRect.left(), baseRect.bottom() - rl);
            path.lineTo(baseRect.left(), baseRect.top() + rl);
            path.quadTo(baseRect.left(), baseRect.top(), baseRect.left() + rl, baseRect.top());
            path.closeSubpath();
            painter->drawPath(path);
        }
    }
}

//______________________________________________________________________________
void Helper::renderDialGroove(QPainter *painter, const QRectF &rect, const QColor &fg, const QColor &bg, qreal first, qreal last) const
{
    // setup painter
    painter->setRenderHint(QPainter::Antialiasing, true);

    const QRectF baseRect(rect);

    // content
    if (fg.isValid()) {
        const qreal penWidth(Metrics::Slider_GrooveThickness);
        const QRectF grooveRect(rect.adjusted(penWidth / 2, penWidth / 2, -penWidth / 2, -penWidth / 2));

        // setup angles
        const int angleStart(first * 180 * 16 / M_PI);
        const int angleSpan((last - first) * 180 * 16 / M_PI);
        const QPen bgPen(fg, penWidth, Qt::SolidLine, Qt::RoundCap);
        const QPen fgPen(transparentize(KColorUtils::overlayColors(bg, alphaColor(fg, 0.5)), frameIntensityBias()), penWidth - 2, Qt::SolidLine, Qt::RoundCap);

        // setup pen
        if (angleSpan != 0) {
            painter->setPen(bgPen);
            painter->setBrush(Qt::NoBrush);
            painter->drawArc(grooveRect, angleStart, angleSpan);
            painter->setPen(fgPen);
            painter->drawArc(grooveRect, angleStart, angleSpan);
        }
    }
}

//______________________________________________________________________________
void Helper::initSliderStyleOption(const QSlider *slider, QStyleOptionSlider *option) const
{
    option->initFrom(slider);
    option->subControls = QStyle::SC_None;
    option->activeSubControls = QStyle::SC_None;
    option->orientation = slider->orientation();
    option->maximum = slider->maximum();
    option->minimum = slider->minimum();
    option->tickPosition = slider->tickPosition();
    option->tickInterval = slider->tickInterval();
    option->upsideDown = (slider->orientation() == Qt::Horizontal) //
        ? (slider->invertedAppearance() != (option->direction == Qt::RightToLeft))
        : (!slider->invertedAppearance());
    option->direction = Qt::LeftToRight; // we use the upsideDown option instead
    option->sliderPosition = slider->sliderPosition();
    option->sliderValue = slider->value();
    option->singleStep = slider->singleStep();
    option->pageStep = slider->pageStep();
    if (slider->orientation() == Qt::Horizontal) {
        option->state |= QStyle::State_Horizontal;
    }
    // Can't fetch activeSubControls, because it's private API
}

//______________________________________________________________________________
QRectF Helper::pathForSliderHandleFocusFrame(QPainterPath &focusFramePath, const QRectF &rect, int hmargin, int vmargin) const
{
    // Mimics path and adjustments of renderSliderHandle
    QRectF frameRect(rect);
    frameRect.translate(hmargin, vmargin);
    frameRect.adjust(1, 1, -1, -1);
    frameRect = strokedRect(frameRect);
    focusFramePath.addEllipse(frameRect);
    frameRect.adjust(-hmargin, -vmargin, hmargin, vmargin);
    focusFramePath.addEllipse(frameRect);
    return frameRect;
}

//______________________________________________________________________________
void Helper::renderSliderHandle(QPainter *painter, const QRectF &rect, const QColor &color, const QColor &outline, const QColor &shadow, bool sunken) const
{
    // setup painter
    painter->setRenderHint(QPainter::Antialiasing, true);

    const bool horizontal = rect.height() >= rect.width();
    QRectF pillRect;
    if (horizontal) {
        // Vertical pill handle for horizontal slider
        const qreal w = Metrics::Slider_HandleWidth;
        const qreal h = rect.height();
        pillRect = QRectF(rect.center().x() - w / 2.0, rect.top(), w, h);
    } else {
        // Horizontal pill handle for vertical slider
        const qreal w = rect.width();
        const qreal h = Metrics::Slider_HandleWidth;
        pillRect = QRectF(rect.left(), rect.center().y() - h / 2.0, w, h);
    }

    const qreal radius = 0.5 * qMin(pillRect.width(), pillRect.height());

    painter->setPen(Qt::NoPen);
    painter->setBrush(color);
    painter->drawRoundedRect(pillRect, radius, radius);
}

//______________________________________________________________________________
void Helper::renderProgressBarGroove(QPainter *painter, const QRectF &rect, const QColor &fg, const QColor &bg) const
{
    // setup painter
    painter->setRenderHint(QPainter::Antialiasing, true);

    QRectF baseRect(rect);
    baseRect.adjust(0.5, 0.5, -0.5, -0.5);
    const qreal radius(0.5 * Metrics::ProgressBar_Thickness);

    // content
    if (fg.isValid()) {
        painter->setPen(QPen(transparentize(fg, frameIntensityBias()), PenWidth::Frame));
        painter->setBrush(KColorUtils::overlayColors(bg, alphaColor(fg, 0.7)));
        painter->drawRoundedRect(baseRect, radius, radius);
    }
}

//______________________________________________________________________________
void Helper::renderProgressBarBusyContents(QPainter *painter,
                                           const QRectF &rect,
                                           const QColor &first,
                                           const QColor &second,
                                           bool horizontal,
                                           bool reverse,
                                           int progress) const
{
    // setup painter
    painter->setRenderHint(QPainter::Antialiasing, true);

    const QRectF baseRect(rect);
    const qreal radius(0.5 * Metrics::ProgressBar_Thickness);

    // setup brush
    QPixmap pixmap(horizontal ? 2 * Metrics::ProgressBar_BusyIndicatorSize : 1, horizontal ? 1 : 2 * Metrics::ProgressBar_BusyIndicatorSize);
    pixmap.fill(second);
    if (horizontal) {
        QPainter painter(&pixmap);
        painter.setBrush(first);
        painter.setPen(Qt::NoPen);

        progress %= 2 * Metrics::ProgressBar_BusyIndicatorSize;
        if (reverse) {
            progress = 2 * Metrics::ProgressBar_BusyIndicatorSize - progress - 1;
        }
        painter.drawRect(QRect(0, 0, Metrics::ProgressBar_BusyIndicatorSize, 1).translated(progress, 0));

        if (progress > Metrics::ProgressBar_BusyIndicatorSize) {
            painter.drawRect(QRect(0, 0, Metrics::ProgressBar_BusyIndicatorSize, 1).translated(progress - 2 * Metrics::ProgressBar_BusyIndicatorSize, 0));
        }

    } else {
        QPainter painter(&pixmap);
        painter.setBrush(first);
        painter.setPen(Qt::NoPen);

        progress %= 2 * Metrics::ProgressBar_BusyIndicatorSize;
        progress = 2 * Metrics::ProgressBar_BusyIndicatorSize - progress - 1;
        painter.drawRect(QRect(0, 0, 1, Metrics::ProgressBar_BusyIndicatorSize).translated(0, progress));

        if (progress > Metrics::ProgressBar_BusyIndicatorSize) {
            painter.drawRect(QRect(0, 0, 1, Metrics::ProgressBar_BusyIndicatorSize).translated(0, progress - 2 * Metrics::ProgressBar_BusyIndicatorSize));
        }
    }

    painter->setPen(Qt::NoPen);
    painter->setBrush(pixmap);
    painter->drawRoundedRect(baseRect, radius, radius);
}

//______________________________________________________________________________
void Helper::renderScrollBarHandle(QPainter *painter, const QRectF &rect, const QColor &fg, const QColor &bg) const
{
    // setup painter
    painter->setRenderHint(QPainter::Antialiasing, true);

    const QRectF baseRect(rect);
    const qreal radius = 0.5 * std::min(baseRect.width(), baseRect.height());

    // Material 3 floating pill handle - soft outline-free pill
    painter->setPen(Qt::NoPen);
    painter->setBrush(alphaColor(fg, 0.6));
    painter->drawRoundedRect(baseRect, radius, radius);
}

//______________________________________________________________________________
void Helper::renderScrollBarBorder(QPainter *painter, const QRectF &rect, const QColor &color) const
{
    // content
    if (color.isValid()) {
        painter->setPen(Qt::NoPen);
        painter->setBrush(color);
        painter->drawRect(rect);
    }
}

void Helper::renderStaticTabBarTab(QPainter *painter,
                                   const QRectF &rect,
                                   const QPalette &palette,
                                   const QHash<QByteArray, bool> &stateProperties,
                                   Corners corners,
                                   qreal animation) const
{
    renderTabBarTab(painter, rect, palette, stateProperties, corners, animation);
}

//______________________________________________________________________________
void Helper::renderTabBarTab(QPainter *painter,
                             const QRectF &rect,
                             const QPalette &palette,
                             const QHash<QByteArray, bool> &stateProperties,
                             Corners corners,
                             qreal animation) const
{
    bool enabled = stateProperties.value("enabled", true);
    bool hovered = stateProperties.value("hovered");
    bool selected = stateProperties.value("selected");
    bool animated = animation != AnimationData::OpacityInvalid;

    painter->setRenderHint(QPainter::Antialiasing, true);

    // Material 3 Primary Tab Bar:
    // Flat background, active bottom indicator line (3px Primary) under selected tab
    if (selected) {
        // Draw active bottom indicator line (Primary)
        const qreal indicatorHeight = 3.0;
        const qreal lineY = rect.bottom() - indicatorHeight;
        const QRectF indicatorRect(rect.left(), lineY, rect.width(), indicatorHeight);
        const qreal indRadius = indicatorHeight / 2.0;

        painter->setPen(Qt::NoPen);
        painter->setBrush(palette.color(QPalette::Highlight));
        painter->drawRoundedRect(indicatorRect, indRadius, indRadius);

    } else if (hovered && enabled) {
        // Subtle hover effect
        painter->setPen(Qt::NoPen);
        painter->setBrush(alphaColor(palette.color(QPalette::Highlight), 0.08));
        painter->drawRoundedRect(rect.adjusted(2, 2, -2, -2), 4, 4);
    }
}

//______________________________________________________________________________
void Helper::renderArrow(QPainter *painter, const QRectF &rect, const QColor &color, ArrowOrientation orientation) const
{
    int size = std::min({rect.toRect().width(), rect.toRect().height(), Metrics::ArrowSize});
    // No point in trying to draw if it's too small
    if (size <= 0) {
        return;
    }

    qreal penOffset = PenWidth::Symbol / 2.0;
    qreal center = size / 2.0;
    qreal maxExtent = size * 0.75;
    qreal minExtent = size / 4.0;
    qreal sizeOffset = 0;
    int remainder = size % 4;
    if (remainder == 2) {
        sizeOffset = 0.5;
    } else if (remainder == 1) {
        sizeOffset = -0.25;
    } else if (remainder == 3) {
        sizeOffset = 0.25;
    }

    QPolygonF arrow;
    switch (orientation) {
    case ArrowUp:
        arrow = QVector<QPointF>{
            {penOffset, maxExtent - penOffset - sizeOffset}, // left
            {center, minExtent - sizeOffset}, // mid
            {size - penOffset, maxExtent - penOffset - sizeOffset} // right
        };
        break;
    case ArrowDown:
        arrow = QVector<QPointF>{
            {penOffset, minExtent + penOffset + sizeOffset}, // left
            {center, maxExtent + sizeOffset}, // mid
            {size - penOffset, minExtent + penOffset + sizeOffset} // right
        };
        break;
    case ArrowLeft:
        arrow = QVector<QPointF>{
            {maxExtent - penOffset - sizeOffset, penOffset}, // top
            {minExtent - sizeOffset, center}, // mid
            {maxExtent - penOffset - sizeOffset, size - penOffset}, // bottom
        };
        break;
    case ArrowRight:
        arrow = QVector<QPointF>{
            {minExtent + penOffset + sizeOffset, penOffset}, // top
            {maxExtent + sizeOffset, center}, // mid
            {minExtent + penOffset + sizeOffset, size - penOffset}, // bottom
        };
        break;
    default:
        break;
    }

    arrow.translate(rect.x() + (rect.width() - size) / 2.0, rect.y() + (rect.height() - size) / 2.0);

    painter->save();
    painter->setRenderHints(QPainter::Antialiasing);
    painter->setBrush(Qt::NoBrush);
    QPen pen(color, 1.5);
    pen.setCapStyle(Qt::RoundCap);
    pen.setJoinStyle(Qt::RoundJoin);
    painter->setPen(pen);
    painter->drawPolyline(arrow);
    painter->restore();
}

//______________________________________________________________________________
void Helper::renderDecorationButton(QPainter *painter, const QRectF &rect, const QColor &color, ButtonType buttonType, bool inverted) const
{
    painter->save();
    painter->setViewport(rect.toRect());
    painter->setWindow(0, 0, 18, 18);
    painter->setRenderHints(QPainter::Antialiasing);

    // initialize pen
    QPen pen;
    pen.setCapStyle(Qt::RoundCap);
    pen.setJoinStyle(Qt::MiterJoin);

    if (inverted) {
        // render circle
        painter->setPen(Qt::NoPen);
        painter->setBrush(color);
        painter->drawEllipse(QRectF(0, 0, 18, 18));

        // take out the inner part
        painter->setCompositionMode(QPainter::CompositionMode_DestinationOut);
        painter->setBrush(Qt::NoBrush);
        pen.setColor(Qt::black);

    } else {
        painter->setBrush(Qt::NoBrush);
        pen.setColor(color);
    }

    pen.setCapStyle(Qt::RoundCap);
    pen.setJoinStyle(Qt::MiterJoin);
    pen.setWidthF(PenWidth::Symbol * qMax(1.0, 18.0 / rect.width()));
    painter->setPen(pen);

    switch (buttonType) {
    case ButtonClose: {
        painter->drawLine(QPointF(5, 5), QPointF(13, 13));
        painter->drawLine(13, 5, 5, 13);
        break;
    }

    case ButtonMaximize: {
        painter->drawPolyline(QVector<QPointF>{QPointF(4, 11), QPointF(9, 6), QPointF(14, 11)});
        break;
    }

    case ButtonMinimize: {
        painter->drawPolyline(QVector<QPointF>{QPointF(4, 7), QPointF(9, 12), QPointF(14, 7)});
        break;
    }

    case ButtonRestore: {
        pen.setJoinStyle(Qt::RoundJoin);
        painter->setPen(pen);
        painter->drawPolygon(QVector<QPointF>{QPointF(4.5, 9), QPointF(9, 4.5), QPointF(13.5, 9), QPointF(9, 13.5)});
        break;
    }

    default:
        break;
    }

    painter->restore();
}

//______________________________________________________________________________
void Helper::renderRoundedRectShadow(QPainter *painter, const QRectF &rect, const QColor &color, qreal radius) const
{
    if (!color.isValid()) {
        return;
    }

    painter->setRenderHint(QPainter::Antialiasing, true);

    qreal adjustment = 0.5 * PenWidth::Shadow; // Translate for the pen
    QRectF shadowRect = rect.adjusted(adjustment, adjustment, -adjustment, adjustment);

    painter->setPen(QPen(color, PenWidth::Shadow));
    painter->setBrush(Qt::NoBrush);
    painter->drawRoundedRect(shadowRect, radius, radius);
}

//______________________________________________________________________________
void Helper::renderEllipseShadow(QPainter *painter, const QRectF &rect, const QColor &color) const
{
    if (!color.isValid()) {
        return;
    }

    painter->save();

    // Clipping does not improve performance here

    qreal adjustment = 0.5 * PenWidth::Shadow; // Adjust for the pen

    qreal radius = rect.width() / 2 - adjustment;

    /* The right side is offset by +0.5 for the visible part of the shadow.
     * The other sides are offset by +0.5 or -0.5 because of the pen.
     */
    QRectF shadowRect = rect.adjusted(adjustment, adjustment, adjustment, -adjustment);

    painter->translate(rect.center());
    painter->rotate(45);
    painter->translate(-rect.center());
    painter->setPen(color);
    painter->setBrush(Qt::NoBrush);
    painter->drawRoundedRect(shadowRect, radius, radius);

    painter->restore();
}

void Helper::renderViewItemPosition(QPainter *painter,
                                    const QStyleOptionViewItem::ViewItemPosition &pos,
                                    const Qt::LayoutDirection direction,
                                    const QRectF &rect,
                                    const QBrush &bg,
                                    const QColor &outline) const
{
    Q_UNUSED(outline);
    painter->save();
    painter->setRenderHint(QPainter::Antialiasing, true);
    const bool reverse = direction == Qt::RightToLeft;

    Corners corners = {};
    QRectF r = rect;

    switch (pos) {
    case QStyleOptionViewItem::Invalid:
        corners = AllCorners;
        break;
    case QStyleOptionViewItem::Beginning:
        corners = reverse ? (CornerTopRight | CornerBottomRight) : (CornerTopLeft | CornerBottomLeft);
        break;
    case QStyleOptionViewItem::Middle:
        corners = {};
        break;
    case QStyleOptionViewItem::End:
        corners = reverse ? (CornerTopLeft | CornerBottomLeft) : (CornerTopRight | CornerBottomRight);
        break;
    case QStyleOptionViewItem::OnlyOne:
        corners = AllCorners;
        break;
    }

    const qreal radius = qMin(r.height() / 2.0, 8.0);
    painter->setBrush(bg);
    painter->setPen(Qt::NoPen);

    QPainterPath path = roundedPath(r, corners, radius);
    painter->drawPath(path);

    painter->restore();
}

//______________________________________________________________________________
bool Helper::isX11()
{
    static const bool s_isX11 = KWindowSystem::isPlatformX11();
    return s_isX11;
}

//______________________________________________________________________________
bool Helper::isWayland()
{
    static const bool s_isWayland = KWindowSystem::isPlatformWayland();
    return s_isWayland;
}

//______________________________________________________________________________
QRectF Helper::strokedRect(const QRectF &rect, const qreal penWidth) const
{
    /* With a pen stroke width of 1, the rectangle should have each of its
     * sides moved inwards by half a pixel. This allows the stroke to be
     * pixel perfect instead of blurry from sitting between pixels and
     * prevents the rectangle with a stroke from becoming larger than the
     * original size of the rectangle.
     */
    qreal adjustment = 0.5 * penWidth;
    return rect.adjusted(adjustment, adjustment, -adjustment, -adjustment);
}

QMargins Helper::itemViewItemMargins(const QStyleOptionViewItem *option) const
{
    QMargins margins(Metrics::ItemView_ItemMarginLeft, Metrics::ItemView_ItemMarginTop, Metrics::ItemView_ItemMarginRight, Metrics::ItemView_ItemMarginBottom);
    if (!option) {
        return margins;
    }

    const QFrame *frame = qobject_cast<const QFrame *>(option->widget);
    const QAbstractItemView *abstractItemView = qobject_cast<const QAbstractItemView *>(option->widget);

    const bool isFirst = option->index.row() == 0;
    const bool hasFrame = frame && frame->frameShape() == QFrame::StyledPanel;
    const bool reverse = option->direction == Qt::RightToLeft;

    if (isFirst) {
        margins.setTop(Metrics::ItemView_FirstItemTopMarginHeight);
    }

    // Breeze frame has one extra white pixel
    if (hasFrame) {
        margins -= {1, isFirst ? 1 : 0, 1, 0};
    }

    // If a treeview wants to show the highlight separate for each column, always draw rounded borders
    // if (tree && !tree->allColumnsShowFocus()) {
    if (abstractItemView && abstractItemView->selectionBehavior() != QAbstractItemView::SelectRows) {
        return margins;
    }

    if ((reverse && option->viewItemPosition == QStyleOptionViewItem::End) || (!reverse && option->viewItemPosition == QStyleOptionViewItem::Beginning)
        || option->viewItemPosition == QStyleOptionViewItem::Middle) {
        margins.setRight(0);
    }
    if ((reverse && option->viewItemPosition == QStyleOptionViewItem::Beginning) || (!reverse && option->viewItemPosition == QStyleOptionViewItem::End)
        || option->viewItemPosition == QStyleOptionViewItem::Middle) {
        margins.setLeft(0);
    }

    return margins;
}

//______________________________________________________________________________
QPainterPath Helper::roundedPath(const QRectF &rect, Corners corners, qreal radius) const
{
    QPainterPath path;

    // simple cases
    if (corners == 0) {
        path.addRect(rect);
        return path;
    }

    if (corners == AllCorners) {
        path.addRoundedRect(rect, radius, radius);
        return path;
    }

    const QSizeF cornerSize(2 * radius, 2 * radius);

    // rotate counterclockwise
    // top left corner
    if (corners & CornerTopLeft) {
        path.moveTo(rect.topLeft() + QPointF(radius, 0));
        path.arcTo(QRectF(rect.topLeft(), cornerSize), 90, 90);

    } else {
        path.moveTo(rect.topLeft());
    }

    // bottom left corner
    if (corners & CornerBottomLeft) {
        path.lineTo(rect.bottomLeft() - QPointF(0, radius));
        path.arcTo(QRectF(rect.bottomLeft() - QPointF(0, 2 * radius), cornerSize), 180, 90);

    } else {
        path.lineTo(rect.bottomLeft());
    }

    // bottom right corner
    if (corners & CornerBottomRight) {
        path.lineTo(rect.bottomRight() - QPointF(radius, 0));
        path.arcTo(QRectF(rect.bottomRight() - QPointF(2 * radius, 2 * radius), cornerSize), 270, 90);

    } else {
        path.lineTo(rect.bottomRight());
    }

    // top right corner
    if (corners & CornerTopRight) {
        path.lineTo(rect.topRight() + QPointF(0, radius));
        path.arcTo(QRectF(rect.topRight() - QPointF(2 * radius, 0), cornerSize), 0, 90);

    } else {
        path.lineTo(rect.topRight());
    }

    path.closeSubpath();
    return path;
}

//________________________________________________________________________________________________________
bool Helper::compositingActive() const
{
    if (isX11()) {
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
        return KWindowSystem::compositingActive();
#elif __has_include(<KX11Extras>)
        return KX11Extras::compositingActive();
#endif
    }

    return true;
}

//____________________________________________________________________
bool Helper::hasAlphaChannel(const QWidget *widget) const
{
    return compositingActive() && widget && widget->testAttribute(Qt::WA_TranslucentBackground);
}

//______________________________________________________________________________________

QPixmap Helper::coloredIcon(const QIcon &icon, const QPalette &palette, const QSize &size, qreal devicePixelRatio, QIcon::Mode mode, QIcon::State state)
{
    const QPalette activePalette = KIconLoader::global()->customPalette();
    const bool changePalette = activePalette != palette;
    if (changePalette) {
        KIconLoader::global()->setCustomPalette(palette);
    }
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    const QPixmap pixmap = icon.pixmap(size, devicePixelRatio, mode, state);
#else
    Q_UNUSED(devicePixelRatio);
    const QPixmap pixmap = icon.pixmap(size, mode, state);
#endif
    if (changePalette) {
        if (activePalette == QPalette()) {
            KIconLoader::global()->resetPalette();
        } else {
            KIconLoader::global()->setCustomPalette(activePalette);
        }
    }
    return pixmap;
}

bool Helper::shouldDrawToolsArea(const QWidget *widget) const
{
    if (!widget) {
        return false;
    }
    static bool isAuto = false;
    static QString borderSize;
    if (!_cachedAutoValid) {
        KConfigGroup kdecorationGroup(_kwinConfig->group(QStringLiteral("org.kde.kdecoration2")));
        isAuto = kdecorationGroup.readEntry("BorderSizeAuto", true);
        borderSize = kdecorationGroup.readEntry("BorderSize", "Normal");
        _cachedAutoValid = true;
    }
    if (isAuto) {
        auto window = widget->window();
        if (qobject_cast<const QDialog *>(widget)) {
            return true;
        }
        if (window) {
            auto handle = window->windowHandle();
            if (handle) {
                auto toolbar = qobject_cast<const QToolBar *>(widget);
                if (toolbar) {
                    if (toolbar->isFloating()) {
                        return false;
                    }
                }
                return true;
            }
        } else {
            return false;
        }
    }
    if (borderSize != QStringLiteral("None") && borderSize != QStringLiteral("NoSides")) {
        return false;
    }
    return true;
}

Qt::Edges Helper::menuSeamlessEdges(const QWidget *widget)
{
    if (widget) {
        auto edges = widget->property(PropertyNames::menuSeamlessEdges).value<Qt::Edges>();
        // Fallback to older property
        if (edges == Qt::Edges() && widget->property(PropertyNames::isTopMenu).toBool()) {
            edges = Qt::TopEdge;
        }
        return edges;
    }
    return Qt::Edges();
}

qreal Helper::devicePixelRatio(QPainter *painter) const
{
    return painter->device() ? painter->device()->devicePixelRatioF() : qApp->devicePixelRatio();
}
}

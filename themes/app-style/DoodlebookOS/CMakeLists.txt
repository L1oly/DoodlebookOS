cmake_minimum_required(VERSION 3.16)
project(doodlebookos_style VERSION 6.8.80 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(QT_NO_CREATE_VERSIONLESS_TARGETS ON)
set(QT_NO_CREATE_VERSIONLESS_FUNCTIONS ON)
set(QT_MAJOR_VERSION 6)

find_package(ECM 5.102.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs6)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMQtDeclareLoggingCategory)

find_package(Qt6 REQUIRED CONFIG COMPONENTS Core Gui DBus Widgets Quick)
find_package(KF6 REQUIRED COMPONENTS
    CoreAddons
    Config
    ConfigWidgets
    GuiAddons
    I18n
    IconThemes
    WindowSystem
    ColorScheme
)

set(DOODLEBOOKOS_HAVE_QTQUICK 1)
set(HAVE_QTDBUS 1)
set(DOODLEBOOKOS_HAVE_KSTYLE 0)

configure_file(config.h.cmake ${CMAKE_CURRENT_BINARY_DIR}/config.h)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/animations
    ${CMAKE_CURRENT_SOURCE_DIR}/debug
    ${CMAKE_CURRENT_BINARY_DIR}
)

set(doodlebookos_PART_SRCS
    boxshadowrenderer.cpp
    animations/animation.cpp
    animations/animations.cpp
    animations/animationdata.cpp
    animations/baseengine.cpp
    animations/busyindicatordata.cpp
    animations/busyindicatorengine.cpp
    animations/dialdata.cpp
    animations/dialengine.cpp
    animations/enabledata.cpp
    animations/genericdata.cpp
    animations/headerviewdata.cpp
    animations/headerviewengine.cpp
    animations/scrollbardata.cpp
    animations/scrollbarengine.cpp
    animations/spinboxengine.cpp
    animations/spinboxdata.cpp
    animations/stackedwidgetdata.cpp
    animations/stackedwidgetengine.cpp
    animations/tabbarengine.cpp
    animations/tabbardata.cpp
    animations/toolboxengine.cpp
    animations/transitiondata.cpp
    animations/transitionwidget.cpp
    animations/widgetstateengine.cpp
    animations/widgetstatedata.cpp
    debug/widgetexplorer.cpp
    addeventfilter.cpp
    blurhelper.cpp
    frameshadow.cpp
    helper.cpp
    mdiwindowshadow.cpp
    mnemonics.cpp
    propertynames.cpp
    shadowhelper.cpp
    splitterproxy.cpp
    style.cpp
    styleplugin.cpp
    tileset.cpp
    windowmanager.cpp
    toolsareamanager.cpp
)

kconfig_add_kcfg_files(doodlebookos_PART_SRCS settings.kcfgc)
kconfig_add_kcfg_files(doodlebookos_PART_SRCS styleconfigdata.kcfgc)

add_library(doodlebookos6 MODULE ${doodlebookos_PART_SRCS})

ecm_qt_declare_logging_category(doodlebookos6
    HEADER
        logging.h
    IDENTIFIER
        DOODLEBOOKOS
    CATEGORY_NAME
        doodlebookos6
    DEFAULT_SEVERITY
        Warning
)

set_target_properties(doodlebookos6 PROPERTIES
    OUTPUT_NAME doodlebookos6
)

target_link_libraries(doodlebookos6
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Widgets
        Qt6::DBus
        Qt6::Quick
        KF6::CoreAddons
        KF6::ConfigCore
        KF6::ConfigGui
        KF6::GuiAddons
        KF6::IconThemes
        KF6::WindowSystem
        KF6::ColorScheme
)

install(TARGETS doodlebookos6 DESTINATION ${KDE_INSTALL_QTPLUGINDIR}/styles/)
install(FILES doodlebookos.themerc DESTINATION ${KDE_INSTALL_DATADIR}/kstyle/themes)

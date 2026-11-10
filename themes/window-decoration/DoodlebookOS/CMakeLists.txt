cmake_minimum_required(VERSION 3.16)
project(doodlebookos_decoration VERSION 6.8.80 LANGUAGES CXX)

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

find_package(Qt6 REQUIRED CONFIG COMPONENTS Core Gui DBus Widgets Svg)
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
find_package(KDecoration3 REQUIRED)

include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${CMAKE_CURRENT_BINARY_DIR})

set(doodlebookos_decoration_SRCS
    boxshadowrenderer.cpp
    button.cpp
    decoration.cpp
    settingsprovider.cpp
)

kconfig_add_kcfg_files(doodlebookos_decoration_SRCS settings.kcfgc)

add_library(doodlebookos_decoration MODULE ${doodlebookos_decoration_SRCS})

set_target_properties(doodlebookos_decoration PROPERTIES
    OUTPUT_NAME org.doodlebookos.decoration
)

target_link_libraries(doodlebookos_decoration
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::DBus
        Qt6::Widgets
        Qt6::Svg
        KF6::CoreAddons
        KF6::ConfigCore
        KF6::ConfigGui
        KF6::GuiAddons
        KF6::I18n
        KF6::IconThemes
        KF6::ColorScheme
        KF6::WindowSystem
        KDecoration3::KDecoration
)

install(TARGETS doodlebookos_decoration DESTINATION ${KDE_INSTALL_PLUGINDIR}/org.kde.kdecoration3)

cmake_minimum_required(VERSION 3.16)
project(autoPurseManager VERSION 1.0.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
# 仅在 Windows 桌面且调用方没有显式指定 Qt 路径时，使用本机默认安装位置；
# Android 等交叉编译工具链会通过 -DCMAKE_PREFIX_PATH 提供自己的 Qt。
if(WIN32 AND NOT ANDROID AND NOT DEFINED CMAKE_PREFIX_PATH)
    set(CMAKE_PREFIX_PATH "C:/Qt/Qt6.12/6.12.0/mingw_64")
endif()

find_package(Qt6 REQUIRED COMPONENTS
    Core Gui Sql Quick Qml QuickDialogs2 QuickControls2 Concurrent Svg
)
qt_standard_project_setup()

if(Qt6Gui_VERSION VERSION_GREATER_EQUAL "6.10.0")
    find_package(Qt6 REQUIRED COMPONENTS GuiPrivate)
endif()

# QXlsx 源码已并入本仓库（qxlsx/），作为项目内部静态库直接参与编译
set(QXLSX_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/qxlsx)
file(GLOB QXLSX_SOURCES CONFIGURE_DEPENDS ${QXLSX_ROOT}/source/*.cpp)
file(GLOB QXLSX_HEADERS CONFIGURE_DEPENDS ${QXLSX_ROOT}/header/*.h)

add_library(qxlsx STATIC ${QXLSX_SOURCES} ${QXLSX_HEADERS})
target_include_directories(qxlsx PUBLIC ${QXLSX_ROOT}/header)
target_link_libraries(qxlsx PUBLIC Qt6::Core Qt6::Gui PRIVATE Qt6::GuiPrivate)
target_compile_definitions(qxlsx PRIVATE
    QT_NO_KEYWORDS
    QT_NO_CAST_TO_ASCII
    QT_NO_CAST_FROM_ASCII
    QT_NO_URL_CAST_FROM_STRING
    QT_NO_CAST_FROM_BYTEARRAY
    QT_USE_QSTRINGBUILDER
    QT_NO_SIGNALS_SLOTS_KEYWORDS
    QT_USE_FAST_OPERATOR_PLUS
    QT_DISABLE_DEPRECATED_BEFORE=0x060600
)
if(NOT WIN32)
    # Windows 下与 Qt 自身的严格迭代器设置冲突，会导致链接错误
    target_compile_definitions(qxlsx PRIVATE QT_STRICT_ITERATORS)
endif()

qt_add_executable(autoPurseManager
    main.cpp
    core/billparser.cpp
    core/billstorage.cpp
    core/categoryrules.cpp
    core/billclassifier.cpp
    core/importfile.cpp
    core/importfile.h
    model/billmodel.cpp
    model/billmodel.h
    model/accountmanager.cpp
    model/accountmanager.h
    model/languagemanager.cpp
    model/languagemanager.h
    thememanager.cpp
    thememanager.h
    model/forecastengine.cpp
    model/forecastengine.h
)

qt_add_qml_module(autoPurseManager
    URI AutoPurse
    VERSION 1.0
    QML_FILES
        ui/Main.qml
        ui/StartPage.qml
        ui/SettingsPage.qml
        ui/HistoryPage.qml
        ui/LineChart.qml
        ui/PieChart.qml
        ui/YearWheel.qml
        ui/MonthWheel.qml
        ui/YearMonthWheel.qml
)

target_include_directories(autoPurseManager PRIVATE
    ${CMAKE_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/core
    ${CMAKE_SOURCE_DIR}/model
)

qt_add_resources(autoPurseManager "translations"
    PREFIX "/"
    FILES translations.json themes.json
)

target_link_libraries(autoPurseManager PRIVATE
    Qt6::Core Qt6::Gui Qt6::Sql Qt6::Quick Qt6::Qml Qt6::Svg
    Qt6::QuickDialogs2
    Qt6::QuickControls2
    Qt6::Concurrent
    qxlsx
)

qt_add_resources(autoPurseManager "icons"
    PREFIX "/"
    FILES icon.svg
)
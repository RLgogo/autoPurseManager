cmake_minimum_required(VERSION 3.16)
project(autoPurseManager VERSION 1.0.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_PREFIX_PATH "C:/Qt/Qt6.12/6.12.0/mingw_64")

find_package(Qt6 REQUIRED COMPONENTS 
Core Gui Sql Quick Qml Charts QuickDialogs2 QuickControls2 Concurrent Svg
)
qt_standard_project_setup()

add_subdirectory(third_party/QXlsx/QXlsx)

qt_add_executable(autoPurseManager
    main.cpp
    core/billparser.cpp
    core/billstorage.cpp
    core/categoryrules.cpp
    core/billclassifier.cpp
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
    Qt6::Charts Qt6::QuickDialogs2
    Qt6::QuickControls2
    Qt6::Concurrent
    QXlsx::QXlsx
)

qt_add_resources(autoPurseManager "icons"
    PREFIX "/"
    FILES icon.svg
)
cmake_minimum_required(VERSION 3.16)
project(mininotes VERSION 0.2.8 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

include(GNUInstallDirs)

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Gui Sql Qml Quick)

set(MININOTES_SOURCES
    src/platform/qt/qt_platform_paths.cpp
    src/application/note_service.cpp
    src/data/sqlite/database.cpp
    src/data/sqlite/sqlite_note_repository.cpp
    src/presentation/note_controller.cpp
    src/presentation/note_list_model.cpp)

set(MININOTES_HEADERS
    src/platform/platform_paths.h
    src/platform/qt/qt_platform_paths.h
    src/application/note_service.h
    src/domain/note.h
    src/domain/inote_repository.h
    src/data/sqlite/database.h
    src/data/sqlite/sqlite_note_repository.h
    src/presentation/note_controller.h
    src/presentation/note_list_model.h)

add_executable(mininotes
    src/app/main.cpp
    ${MININOTES_SOURCES}
    ${MININOTES_HEADERS})

target_include_directories(mininotes PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(mininotes PRIVATE
    Qt${QT_VERSION_MAJOR}::Core
    Qt${QT_VERSION_MAJOR}::Gui
    Qt${QT_VERSION_MAJOR}::Sql
    Qt${QT_VERSION_MAJOR}::Qml
    Qt${QT_VERSION_MAJOR}::Quick)

configure_file(manifest.json.in ${CMAKE_CURRENT_BINARY_DIR}/manifest.json)

option(
    MININOTES_PACKAGE
    "Enable standard Linux desktop installation/package layout"
    OFF
)

if(MININOTES_PACKAGE)
    install(
        TARGETS mininotes
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )

    install(
        DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/qml/
        DESTINATION ${CMAKE_INSTALL_DATADIR}/mininotes/qml
    )

    install(
        FILES
            ${CMAKE_CURRENT_SOURCE_DIR}/packaging/appstream/io.github.Ahmad_J_Bary.UbuntuTouch_Lab.desktop
        DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
    )

    install(
        FILES
            ${CMAKE_CURRENT_SOURCE_DIR}/packaging/appstream/io.github.Ahmad_J_Bary.UbuntuTouch_Lab.metainfo.xml
        DESTINATION ${CMAKE_INSTALL_DATADIR}/metainfo
    )

    install(
        FILES
            ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/mininotes.svg
        DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps
        RENAME io.github.Ahmad_J_Bary.UbuntuTouch_Lab.svg
    )

    set(CPACK_PACKAGE_NAME "mininotes")
    set(CPACK_PACKAGE_VENDOR "MiniNotes Developers")
    set(CPACK_PACKAGE_CONTACT "MiniNotes Developers")
    set(CPACK_PACKAGE_DESCRIPTION_SUMMARY
        "Offline-first notes application"
    )
    set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
    set(CPACK_PACKAGE_INSTALL_DIRECTORY "MiniNotes")

    set(CPACK_DEBIAN_PACKAGE_MAINTAINER "MiniNotes Developers")
    set(CPACK_DEBIAN_PACKAGE_SECTION "utils")
    set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
    set(
        CPACK_DEBIAN_PACKAGE_DEPENDS
        "libqt6sql6-sqlite, qml6-module-qtquick, qml6-module-qtquick-controls, qml6-module-qtquick-layouts, qml6-module-qtquick-window"
    )

    set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
    set(CPACK_STRIP_FILES ON)
    set(CPACK_GENERATOR DEB)

    include(CPack)
else()
    install(TARGETS mininotes RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX})
    install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/qml DESTINATION ${CMAKE_INSTALL_PREFIX})
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/manifest.json DESTINATION ${CMAKE_INSTALL_PREFIX})
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/mininotes.apparmor DESTINATION ${CMAKE_INSTALL_PREFIX})
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/mininotes.desktop DESTINATION ${CMAKE_INSTALL_PREFIX})
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/mininotes.svg
        DESTINATION ${CMAKE_INSTALL_PREFIX}/assets/icons)
endif()

add_custom_command(TARGET mininotes POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_CURRENT_SOURCE_DIR}/qml
        $<TARGET_FILE_DIR:mininotes>/qml)

option(MININOTES_BUILD_TESTS "Build backend functional tests" OFF)
if(MININOTES_BUILD_TESTS)
    enable_testing()
    find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Test)

    add_executable(mininotes_backend_test
        tests/tst_backend.cpp
        ${MININOTES_SOURCES}
        ${MININOTES_HEADERS})

    target_include_directories(mininotes_backend_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

    target_link_libraries(mininotes_backend_test PRIVATE
        Qt${QT_VERSION_MAJOR}::Core
        Qt${QT_VERSION_MAJOR}::Sql
        Qt${QT_VERSION_MAJOR}::Test)

    add_test(NAME mininotes_backend_test COMMAND mininotes_backend_test)

    add_executable(mininotes_service_test
        tests/tst_note_service.cpp
        src/application/note_service.cpp
        src/application/note_service.h
        src/domain/note.h
        src/domain/inote_repository.h)

    target_include_directories(mininotes_service_test PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src)

    target_link_libraries(mininotes_service_test PRIVATE
        Qt${QT_VERSION_MAJOR}::Core
        Qt${QT_VERSION_MAJOR}::Test)

    add_test(NAME mininotes_service_test COMMAND mininotes_service_test)

    add_executable(mininotes_platform_test
        tests/tst_platform_paths.cpp
        src/platform/qt/qt_platform_paths.cpp
        src/platform/qt/qt_platform_paths.h
        src/platform/platform_paths.h)

    target_include_directories(mininotes_platform_test PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src)

    target_link_libraries(mininotes_platform_test PRIVATE
        Qt${QT_VERSION_MAJOR}::Core
        Qt${QT_VERSION_MAJOR}::Test)

    add_test(NAME mininotes_platform_test COMMAND mininotes_platform_test)
endif()

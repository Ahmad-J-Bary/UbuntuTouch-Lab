cmake_minimum_required(VERSION 3.16)
project(mininotes VERSION 0.1.2 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Gui Sql Qml Quick)

set(MININOTES_SOURCES
    src/database.cpp
    src/noterepository.cpp
    src/notecontroller.cpp)

set(MININOTES_HEADERS
    src/note.h
    src/database.h
    src/noterepository.h
    src/notecontroller.h)

add_executable(mininotes
    src/main.cpp
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

install(TARGETS mininotes RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX})
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/qml DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/manifest.json DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/mininotes.apparmor DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/mininotes.desktop DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/mininotes.svg
    DESTINATION ${CMAKE_INSTALL_PREFIX}/assets/icons)

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
endif()
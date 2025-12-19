cmake_minimum_required(VERSION 3.14)
project(ble_plugin LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(ble_plugin STATIC
        ble_plugin.cpp
        ble_plugin.h
)

target_compile_definitions(ble_plugin PRIVATE
        WINVER=0x0A00
        _WIN32_WINNT=0x0A00
)

target_link_libraries(ble_plugin PRIVATE
        flutter
        flutter_wrapper_plugin
        windowsapp
)

target_include_directories(ble_plugin PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
# SPDX-License-Identifier: GPL-3.0-or-later
cmake_minimum_required(VERSION 3.22.1)
project(hams_native LANGUAGES C CXX)

set(OPUS_BUILD_SHARED_LIBRARY OFF CACHE BOOL "" FORCE)
set(OPUS_BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(OPUS_BUILD_PROGRAMS OFF CACHE BOOL "" FORCE)
add_subdirectory(vendor opus-build EXCLUDE_FROM_ALL)

add_library(hams_native SHARED hello.cpp)
find_package(oboe REQUIRED CONFIG)
target_link_libraries(hams_native opus oboe::oboe log android)
target_compile_features(hams_native PRIVATE cxx_std_20)

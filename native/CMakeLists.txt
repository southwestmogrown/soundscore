cmake_minimum_required(VERSION 3.22)

project(soundscore_dsp VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Optimization flags
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

set(CMAKE_CXX_FLAGS_RELEASE "-O2 -DNDEBUG")
set(CMAKE_CXX_FLAGS_DEBUG   "-O0 -g -DDEBUG")

# DSP source files — stubs now, filled in Phase 2
set(DSP_SOURCES
    src/soundscore_dsp.cpp
    src/yin_detector.cpp
    src/onset_detector.cpp
    src/chord_analyzer.cpp
    src/fft_util.cpp
)

add_library(soundscore_dsp SHARED ${DSP_SOURCES})

target_include_directories(soundscore_dsp
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# Android-specific: link against the Android log library
if(ANDROID)
    find_library(android-log log)
    target_link_libraries(soundscore_dsp PRIVATE ${android-log})
    # Required ABI targets: arm64-v8a, armeabi-v7a, x86_64
endif()

# iOS: compile as static library (linked into the app binary)
if(APPLE)
    set_target_properties(soundscore_dsp PROPERTIES
        FRAMEWORK FALSE
        MACOSX_RPATH TRUE
    )
endif()

cmake_minimum_required(VERSION 3.22)

project(soundscore_dsp VERSION 0.2.0 LANGUAGES C CXX)

set(CMAKE_C_STANDARD   11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

set(CMAKE_C_FLAGS_RELEASE   "-O2 -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "-O2 -DNDEBUG")
set(CMAKE_C_FLAGS_DEBUG     "-O0 -g -DDEBUG")
set(CMAKE_CXX_FLAGS_DEBUG   "-O0 -g -DDEBUG")

# ── KissFFT (vendored) ────────────────────────────────────────────────────────
set(KISSFFT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/kissfft)

add_library(kissfft STATIC
    ${KISSFFT_DIR}/kiss_fft.c
    ${KISSFFT_DIR}/kiss_fftr.c
)
target_include_directories(kissfft PUBLIC ${KISSFFT_DIR})
set_target_properties(kissfft PROPERTIES POSITION_INDEPENDENT_CODE ON)

# ── SoundScore DSP shared library ─────────────────────────────────────────────
set(DSP_SOURCES
    src/soundscore_dsp.cpp
    src/fft_util.cpp
    src/yin_detector.cpp
    src/onset_detector.cpp
    src/chord_analyzer.cpp
)

add_library(soundscore_dsp SHARED ${DSP_SOURCES})

target_include_directories(soundscore_dsp
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${KISSFFT_DIR}
)

target_link_libraries(soundscore_dsp PRIVATE kissfft)

# Android: link log library; require arm64-v8a + armeabi-v7a + x86_64
if(ANDROID)
    find_library(android-log log)
    target_link_libraries(soundscore_dsp PRIVATE ${android-log})
endif()

if(APPLE)
    set_target_properties(soundscore_dsp PROPERTIES MACOSX_RPATH TRUE)
endif()

/*
 * Minimal logging stub for KissFFT.
 * On Android: routes to __android_log_print via logcat.
 * Elsewhere: routes to stderr.
 */
#pragma once

#ifdef __ANDROID__
#  include <android/log.h>
#  define KISS_FFT_ERROR(msg, ...)   __android_log_print(ANDROID_LOG_ERROR, "KissFFT", msg, ##__VA_ARGS__)
#  define KISS_FFT_WARNING(msg, ...) __android_log_print(ANDROID_LOG_WARN,  "KissFFT", msg, ##__VA_ARGS__)
#  define KISS_FFT_DEBUG(msg, ...)   __android_log_print(ANDROID_LOG_DEBUG, "KissFFT", msg, ##__VA_ARGS__)
#else
#  include <stdio.h>
#  define KISS_FFT_ERROR(msg, ...)   fprintf(stderr, "[KissFFT ERROR] " msg "\n", ##__VA_ARGS__)
#  define KISS_FFT_WARNING(msg, ...) fprintf(stderr, "[KissFFT WARN]  " msg "\n", ##__VA_ARGS__)
#  define KISS_FFT_DEBUG(msg, ...)   /* no-op in non-debug builds */
#endif

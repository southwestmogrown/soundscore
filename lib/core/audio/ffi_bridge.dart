import 'dart:ffi';
import 'dart:io';

/// Dart FFI bindings to the native soundscore_dsp C++ shared library.
/// Full implementation in Phase 2 (C++ DSP layer).
class DspFfiBridge {
  static DynamicLibrary? _lib;

  static DynamicLibrary get lib {
    _lib ??= Platform.isAndroid
        ? DynamicLibrary.open('libsoundscore_dsp.so')
        : DynamicLibrary.process(); // iOS links statically
    return _lib!;
  }
}
